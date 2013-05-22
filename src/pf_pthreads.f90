!
! Copyright (C) 2012, 2013 Matthew Emmett and Michael Minion.
!
! This file is part of LIBPFASST.
!
! LIBPFASST is free software: you can redistribute it and/or modify it
! under the terms of the GNU General Public License as published by
! the Free Software Foundation, either version 3 of the License, or
! (at your option) any later version.
!
! LIBPFASST is distributed in the hope that it will be useful, but
! WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
! General Public License for more details.
!
! You should have received a copy of the GNU General Public License
! along with LIBPFASST.  If not, see <http://www.gnu.org/licenses/>.
!

! This module implements PTHREADS communications.

module pf_mod_comm_pthreads
  use pf_mod_dtype
  use pf_mod_pfasst
  use pf_mod_timer
  use iso_c_binding

  implicit none

  !
  ! pthread interfaces (see man pthreads)
  !
  interface
     integer(c_int) function pthread_self() &
          bind(c, name='pthread_self')
       use iso_c_binding
     end function pthread_self
  end interface

  interface
     integer(c_int) function pthread_join(thread, valueptr) &
          bind(c, name='pthread_join')
       use iso_c_binding
       integer(c_long), intent(in), value :: thread
       type(c_ptr),     intent(in), value :: valueptr
     end function pthread_join
  end interface

  interface
     integer(c_long) function pthread_create(thread, attr, start, arg) &
          bind(c, name='pthread_create')
       use iso_c_binding
       type(c_ptr), intent(in), value :: thread, attr, start, arg
     end function pthread_create
  end interface

  interface
     subroutine pthread_exit(retval) bind(c, name='pthread_exit')
       use iso_c_binding
       type(c_ptr), intent(in), value :: retval
     end subroutine pthread_exit
  end interface

  !
  ! pfasst pthreads interfaces (see pf_cpthreads.c)
  !
  interface
     type(c_ptr) function pf_pth_create() bind(c, name='pf_pth_create')
       use iso_c_binding
     end function pf_pth_create
  end interface

  interface
     subroutine pf_pth_destroy(pth) bind(c, name='pf_pth_destroy')
       use iso_c_binding
       type(c_ptr), intent(in), value :: pth
     end subroutine pf_pth_destroy
  end interface

  interface
     subroutine pf_pth_wait_send(pth, tag) bind(c, name='pf_pth_wait_send')
       use iso_c_binding
       type(c_ptr), intent(in), value :: pth
       integer(c_int), intent(in), value :: tag
     end subroutine pf_pth_wait_send
  end interface

  interface
     subroutine pf_pth_set_send(pth, tag) bind(c, name='pf_pth_set_send')
       use iso_c_binding
       type(c_ptr), intent(in), value :: pth
       integer(c_int), intent(in), value :: tag
     end subroutine pf_pth_set_send
  end interface

  interface
     subroutine pf_pth_wait_recv(pth, tag) bind(c, name='pf_pth_wait_recv')
       use iso_c_binding
       type(c_ptr), intent(in), value :: pth
       integer(c_int), intent(in), value :: tag
     end subroutine pf_pth_wait_recv
  end interface

  interface
     subroutine pf_pth_set_recv(pth, tag) bind(c, name='pf_pth_set_recv')
       use iso_c_binding
       type(c_ptr), intent(in), value :: pth
       integer(c_int), intent(in), value :: tag
     end subroutine pf_pth_set_recv
  end interface

  interface
     subroutine pf_pth_lock(pth) bind(c, name='pf_pth_lock')
       use iso_c_binding
       type(c_ptr), intent(in), value :: pth
     end subroutine pf_pth_lock
  end interface

  interface
     subroutine pf_pth_unlock(pth) bind(c, name='pf_pth_unlock')
       use iso_c_binding
       type(c_ptr), intent(in), value :: pth
     end subroutine pf_pth_unlock
  end interface

contains

  ! Create a PTHREADS based PFASST communicator (call only once)
  !
  ! This is not thread safe.
  subroutine pf_pthreads_create(pf_comm, nthreads, nlevels)
    type(pf_comm_t), intent(out) :: pf_comm
    integer,         intent(in)  :: nthreads, nlevels

    integer :: t, l

    pf_comm%nproc = nthreads
    allocate(pf_comm%pfs(0:nthreads-1))
    allocate(pf_comm%pfpth(0:nthreads-1,nlevels))

    do t = 0, nthreads-1
       do l = 1, nlevels
          pf_comm%pfpth(t,l) = pf_pth_create()
       end do
    end do

    pf_comm%post => pf_pthreads_post
    pf_comm%recv => pf_pthreads_recv
    pf_comm%send => pf_pthreads_send
    pf_comm%wait => pf_pthreads_wait
    pf_comm%broadcast => pf_pthreads_broadcast
  end subroutine pf_pthreads_create

  ! Setup
  subroutine pf_pthreads_setup(pf_comm, pf)
    type(pf_comm_t), intent(inout) :: pf_comm
    type(pf_pfasst_t), intent(inout), target  :: pf

    integer :: n

    n = pf%rank
    pf_comm%pfs(n) = c_loc(pf)
  end subroutine pf_pthreads_setup

  ! Retrieve the PFASST object associated with the given rank
  subroutine pf_pthreads_get(pf_comm, rank, pf)
    type(pf_comm_t),   intent(in)  :: pf_comm
    integer,           intent(in)  :: rank 
    type(pf_pfasst_t), intent(out), pointer :: pf

    call c_f_pointer(pf_comm%pfs(rank), pf)
  end subroutine pf_pthreads_get

  ! Destroy (call only once)
  subroutine pf_pthreads_destroy(pf_comm)
    type(pf_comm_t), intent(inout) :: pf_comm
    integer :: t, l

    type(pf_pfasst_t), pointer :: pf

    do t = 0, size(pf_comm%pfs)-1
       do l = 1, size(pf_comm%pfpth(t,:))
          call pf_pth_destroy(pf_comm%pfpth(t,l))
       end do
    end do

    do t = 0, pf_comm%nproc-1
       call c_f_pointer(pf_comm%pfs(t), pf)
       call pf_pfasst_destroy(pf)
       deallocate(pf)
    end do

    deallocate(pf_comm%pfs)
    deallocate(pf_comm%pfpth)
  end subroutine pf_pthreads_destroy

  ! Post
  subroutine pf_pthreads_post(pf, level, tag)
    type(pf_pfasst_t), intent(in)    :: pf
    type(pf_level_t),  intent(inout) :: level
    integer,           intent(in)    :: tag
    ! this is intentionally empty
  end subroutine pf_pthreads_post

  ! Receive
  subroutine pf_pthreads_recv(pf, level, tag, blocking)
    type(pf_pfasst_t), intent(inout) :: pf
    type(pf_level_t),  intent(inout) :: level
    integer,           intent(in)    :: tag
    logical,           intent(in)    :: blocking

    type(pf_pfasst_t), pointer :: from
    type(c_ptr) :: pth

    call start_timer(pf, TRECEIVE)

    if (pf%rank > 0) then
       call pf_pthreads_get(pf%comm, pf%rank-1, from)
       pth = pf%comm%pfpth(from%rank, level%level)

       call pf_pth_wait_send(pth, tag)

       call pf_pth_lock(pth)
       level%q0 = from%levels(level%level)%send
       call pf_pth_unlock(pth)

       call pf_pth_set_recv(pth, 0)
    end if

    call end_timer(pf, TRECEIVE)
  end subroutine pf_pthreads_recv

  ! Send
  subroutine pf_pthreads_send(pf, level, tag, blocking)
    type(pf_pfasst_t), intent(inout) :: pf
    type(pf_level_t),  intent(inout) :: level
    integer,           intent(in)    :: tag
    logical,           intent(in)    :: blocking

    type(c_ptr)       :: pth

    call start_timer(pf, TSEND)

    if (pf%rank < pf%comm%nproc-1) then
       pth = pf%comm%pfpth(pf%rank, level%level)

       call pf_pth_wait_recv(pth, 0)

       call pf_pth_lock(pth)
       call level%encap%pack(level%send, level%qend)
       call pf_pth_unlock(pth)

       call pf_pth_set_recv(pth, tag)
       call pf_pth_set_send(pth, tag)
    end if

    call end_timer(pf, TSEND)
  end subroutine pf_pthreads_send

  ! Wait
  subroutine pf_pthreads_wait(pf, level)
    type(pf_pfasst_t), intent(in) :: pf
    integer,           intent(in) :: level

    print *, "PTHREADS WAIT NOT IMPLEMENTED YET"
  end subroutine pf_pthreads_wait

  ! Broadcast
  subroutine pf_pthreads_broadcast(pf, y, nvar, root)
    type(pf_pfasst_t), intent(inout) :: pf
    real(kind=8),      intent(in)    :: y(nvar)
    integer,           intent(in)    :: nvar, root

    stop "PTHREADS BROADCAST NOT IMPLEMENTED YET"
  end subroutine pf_pthreads_broadcast

end module pf_mod_comm_pthreads