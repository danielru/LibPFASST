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
!>  Module containing a collection of "use" statements to simplify
!!  including the common main modules in writing applications that use libpfasst
module pfasst
  use pf_mod_dtype
  use pf_mod_hooks
  use pf_mod_parallel
  use pf_mod_pfasst
#ifndef NOMPI
  use pf_mod_comm_mpi
#endif
  use pf_mod_imexQ
end module pfasst

