program main
  use m_polynom
  use m_acoustic

  implicit none

  integer           :: i,j
  real              :: x,ddx
  type(t_polynom_b) :: bpol
  type(t_polynom_b) :: dbpol
  type(t_polynom_l) :: lpol

  integer         ,parameter :: nb_elem=100
  integer         ,parameter :: ordre=4,DoF=ordre+1  ! Polynoms order
  real            ,parameter :: total_length=1.0
  real            ,parameter :: final_time=2.0
  real            ,parameter :: alpha=2.0            ! Penalisation value
  character(len=*),parameter :: signal='ricker'
  character(len=*),parameter :: boundaries='dirichlet'
  logical         ,parameter :: bernstein=.true.    !If F-> Lagrange Elements
  logical         ,parameter :: F_forte=.true. !Means Strong Formulation (always=T) 
  type(acoustic_problem)     :: problem

  real                       :: t
  integer                    :: n_time_step
  integer         ,parameter :: n_display=100

  real,dimension(DoF) :: coef_test_b,coef_test_l
  real,dimension(DoF*nb_elem) :: work

  integer :: values(1:8), k
  integer,dimension(:), allocatable :: seed

  call date_and_time(values=values)

  call random_seed(size=k)
  allocate(seed(1:k))
  seed(:) = values(8)
  call random_seed(put=seed)
  
  call init_basis_b(ordre)
  call init_basis_l(ordre)

  call create_B2L
  call create_L2B
  call create_derive(ordre)
  
  !*************************************************************************
  !********************* SIMULATION EQUATION ACOUSTIQUE*********************

  call init_problem(problem,nb_elem,DoF,total_length,final_time,alpha,bernstein,&
                    F_forte,signal,boundaries)
  call print_sol(problem,0)
  
  call init_ApAv(problem)
  
  n_time_step=int(final_time/problem%dt)
  print*,'There will be :',n_time_step,'time_step'

  ! call one_time_step(problem)
  ! call print_sol(problem,1)

  ! call system('gnuplot test.gnu')
  ! call system('eog test.png &')
  
  do i=1,n_time_step
     t=(i-1)*problem%dt
     call one_time_step(problem,t)

     if (modulo(i,n_display).eq.0) then
        call print_sol(problem,i/n_display)
     end if
  end do

  open(unit=78,file='script.gnuplot',action='write')
  write(78,*),'load "trace1.gnuplot"'
  write(78,*),'n=',int(n_time_step/n_display)
  write(78,*),'a=',1
  write(78,*),'load "trace2.gnuplot"'
  close(78)
  
  call system('gnuplot5 script.gnuplot')
  call system ('eog animate.gif &')
  
end program main
