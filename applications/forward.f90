program main
  use m_file_function
  use m_polynom
  use m_matrix
  use m_acoustic
  use m_init_application
  use m_animation

  implicit none

  !*************** Main Variables ***********************************************
  type(acoustic_problem)            :: forward

  real                              :: t
  integer                           :: i,j,k
  integer                           :: forward_n_time_step
  real,dimension(:,:),allocatable   :: data_P
  real,dimension(:,:),allocatable   :: data_U

  integer                           :: values(1:8)
  integer,dimension(:), allocatable :: seed
  !******************************************************************************

  call setup_parameters('forward')

  call date_and_time(values=values)
  call random_seed(size=k)
  allocate(seed(1:k))
  seed(:) = values(8)
  call random_seed(put=seed)

  !*********** Polynomial initialization *************
  call init_basis_b(order)
  call init_basis_l(order)
  call create_B2L
  call create_L2B
  call create_derive(order)


  call init_acoustic_problem(forward,nb_elem,DoF,time_scheme,velocity_data,     &
                             density_data,total_length,final_time,alpha,        &
                             bernstein,signal,boundaries,source_loc,receiver_loc)

  forward_n_time_step=forward%n_time_step
  allocate(data_P(0:forward%n_time_step,2))
  allocate(data_U(0:forward%n_time_step,2))

  t=0
  data_P(0,1)=0.0
  data_P(0,2)=0.0
  if (animation.eq.'data_forward') then
     call print_vect(forward%P,nb_elem,DoF,forward%dx,bernstein,0,'FP')
  end if
  do i=1,forward%n_time_step
     t=i*forward%dt
     call progress_bar(i,forward%n_time_step)
     call one_forward_step(forward,t)
     data_P(i,1)=t
     data_P(i,2)=forward%P((receiver_loc-1)*DoF+1)
     if (animation.eq.'data_forward')  then
        if (modulo(i,10).eq.0) then
           call print_vect(forward%P,nb_elem,DoF,forward%dx,bernstein,i,'FP')
        end if
     end if
  end do
  data_U=0.0

  open(unit=22,file='data_P.dat',action='write')
  do i=0,forward%n_time_step
     write(22,*) data_P(i,1),data_P(i,2)
  end do
  close(22)

  call free_acoustic_problem(forward)

  !--------------------- Animation ----------------------------------------------
  call gif_creation(animation,forward_n_time_step,forward_n_time_step)

  !------------------------ Free Variables --------------------------------------
  call free_basis_b
  call free_basis_l
  call free_B2L
  call free_L2B
  call free_derive

end program main