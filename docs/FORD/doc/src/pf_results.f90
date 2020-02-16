!! Module for storing results for eventual output
!
! This file is part of LIBPFASST.
!
!>  Module for the storing results for eventual output
module pf_mod_results
  use pf_mod_dtype
  use pf_mod_utils
  implicit none
  
contains
  subroutine initialize_results(this, nsteps_in, niters_in, nprocs_in, nsweeps_in,rank_in,level_index,outdir,save_residuals)

    class(pf_results_t), intent(inout) :: this
    integer, intent(in) :: nsteps_in, niters_in, nprocs_in, nsweeps_in,rank_in,level_index
    character(len=*), intent(in) :: outdir
    logical, intent(in) :: save_residuals

    character(len = 128) :: fname  !!  output file name for residuals
    character(len = 128) :: datpath  !!  path to output files
    character(len = 256) :: fullname  !!  output file name for residuals
    integer :: istat,system,ierr
    
    !  Set up the directory to dump results
    istat= system('mkdir -p dat')
    if (istat .ne. 0) call pf_stop(__FILE__,__LINE__, "Cannot make directory in initialize_results")       
    istat= system('mkdir -p dat/' // trim(outdir))       
    if (istat .ne. 0) call pf_stop(__FILE__,__LINE__, "Cannot make directory in initialize_results")
    this%datpath= 'dat/' // trim(outdir) // '/'
!    this%datpath=this%datpath //   '/'
    
    if (save_residuals) then
       
       write (fname, "(A16,I0.1,A4)") 'residuals_size_L',level_index,'.dat'
       fullname = trim(this%datpath) // trim(fname)
       
       if (rank_in == 0) then
          open(unit=123, file=trim(fullname), form='formatted')
          write(123,'(I5, I5, I5, I5)') nsteps_in, niters_in, nprocs_in, nsweeps_in
          close(unit=123)
       end if
    end if
       
!    this%dump => dump_results
    this%destroy => destroy_results

    this%nsteps=nsteps_in
    this%nblocks=nsteps_in/nprocs_in
    this%niters=niters_in
    this%nprocs=nprocs_in
    this%nsweeps=nsweeps_in
    this%rank=rank_in
    this%level_index=level_index    

    ierr=0
    if(.not.allocated(this%errors)) allocate(this%errors(niters_in, this%nblocks, nsweeps_in),stat=ierr)
    if (ierr /=0) call pf_stop(__FILE__,__LINE__,'allocate fail, error=',ierr)               
    if(.not.allocated(this%residuals)) allocate(this%residuals(niters_in, this%nblocks, nsweeps_in),stat=ierr)
    if (ierr /=0) call pf_stop(__FILE__,__LINE__,'allocate fail, error=',ierr)                   

    this%errors = -1.0_pfdp
    this%residuals = -1.0_pfdp
  end subroutine initialize_results

  subroutine dump_resids(this)
    type(pf_results_t), intent(inout) :: this
    integer :: i, j, k, istat,system
    character(len = 128) :: fname  !!  output file name for residuals
    character(len = 256) :: fullname  !!  output file name for residuals
    character(len = 128) :: datpath  !!  directory path
    character(len = 128) :: dirname  !!  directory name
    
    datpath = trim(this%datpath) // 'residuals'
    istat= system('mkdir -p ' // trim(datpath))
    if (istat .ne. 0) call pf_stop(__FILE__,__LINE__, "Cannot make directory in dump_resids")

    write (dirname, "(A6,I0.3)") '/Proc_',this%rank
    datpath=trim(datpath) // trim(dirname) 
    istat= system('mkdir -p ' // trim(datpath))
    if (istat .ne. 0) call pf_stop(__FILE__,__LINE__, "Cannot make directory in dump_resids")

    write (fname, "(A5,I0.1,A4)") '/Lev_',this%level_index,'.dat'
    fullname = trim(datpath) // trim(fname)
    !  output residuals
    open(100+this%rank, file=trim(fullname), form='formatted')
    do j = 1, this%nblocks
       do i = 1 , this%niters
          do k = 1, this%nsweeps
             if (this%residuals(i, j, k) .gt. 0.0) then
                write(100+this%rank, '(I4, I4, I4, e22.14)') j,i,k,this%residuals(i, j, k)
             end if
          end do
       end do
    enddo
    close(100+this%rank)

  end subroutine dump_resids
  subroutine dump_errors(this)
    type(pf_results_t), intent(inout) :: this
    integer :: i, j, k, istat,system
    character(len = 128   ) :: fname  !!  output file name for residuals
    character(len = 256   ) :: fullname  !!  output file name for residuals
    character(len = 128   ) :: datpath  !!  directory path

    
    datpath = trim(this%datpath) // 'errors'
    istat= system('mkdir -p ' // trim(datpath))
    
    if (istat .ne. 0) call pf_stop(__FILE__,__LINE__, "Cannot make directory in dump_errors")

    write (fname, "(A6,I0.3,A5,I0.1,A4)") '/Proc_',this%rank,'_Lev_',this%level_index,'.dat'
    fullname = trim(datpath) // trim(fname)
    !  output errors
    open(100+this%rank, file=trim(fullname), form='formatted')
    do j = 1, this%nblocks
       do i = 1 , this%niters
          do k = 1, this%nsweeps
             write(100+this%rank, '(I4, I4, I4, e22.14)') j,i,k,this%errors(i, j, k)
          end do
       end do
    enddo
    close(100+this%rank)

  end subroutine dump_errors

  subroutine dump_timings(pf)
    type(pf_pfasst_t), intent(inout) :: pf
    character(len = 128   ) :: fname  !!  output file name for runtimes
    character(len = 256   ) :: fullname  !!  output file name for runtimes
    character(len = 128   ) :: datpath  !!  directory path
    integer :: istat,j, istream,system

    datpath = 'dat/' // trim(pf%outdir) // '/runtimes'
    istat= system('mkdir -p '// trim(datpath))

    if (istat .ne. 0) call pf_stop(__FILE__,__LINE__, "Cannot make directory in dump_timings")

    !  Write a file with timer names and times
    write (fname, "(A6,I0.3,A4)")  '/Proc_',pf%rank,'.txt'    
    fullname = trim(datpath) // trim(fname)
    istream = 200+pf%rank !  Use processor dependent file number
    !  output timings
    open(istream, file=trim(fullname), form='formatted')
    do j = 1, 100
       if (pf%runtimes(j) > 0.0d0) then
          write(istream, '(a16,  f23.8)') timer_names(j),pf%runtimes(j)
       end if
    end do
    close(istream)
    
    !  Write a file with timer numbers and times
    write (fname, "(A6,I0.3,A4)")  '/Proc_',pf%rank,'.dat'    
    fullname = trim(datpath) // trim(fname)
    istream = 200+pf%rank !  Use processor dependent file number
    !  output timings
    open(istream, file=trim(fullname), form='formatted')
    do j = 1, 100
       if (pf%runtimes(j) > 0.0d0) then
          write(istream, '(I0.3,  f23.8)') j,pf%runtimes(j)
       end if
    end do
    
    close(istream)

  end subroutine dump_timings

  subroutine destroy_results(this)
    type(pf_results_t), intent(inout) :: this
    
    if(allocated(this%errors))  deallocate(this%errors)
    if(allocated(this%residuals))  deallocate(this%residuals)
  end subroutine destroy_results

end module pf_mod_results