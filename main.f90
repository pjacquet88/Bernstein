program main
  use m_file_function
  use m_polynom
  use m_matrix
  use m_acoustic
  use m_adjoint
  use m_adjoint_test
  use m_fwi
  use m_init_application

  implicit none

  !**************** Animation and Outputs ***************************************
  logical,parameter           :: bool_fwi=.true.  ! if F -> just perform forward for data
  !******************************************************************************

  !*************** Main Variables ***********************************************
  type(acoustic_problem)            :: forward,backward
  type(t_fwi)                       :: fwi
  real,dimension(:,:),allocatable   :: data_P
  real,dimension(:,:),allocatable   :: data_U

  real                              :: t
  integer                           :: i,j
  integer                           :: values(1:8), k
  integer,dimension(:), allocatable :: seed
  logical                           :: file_exists
  integer                           :: data_time_step
  integer                           :: fwi_time_step
  integer                           :: n_frame
  !******************************************************************************

  call setup_parameters()
  
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

  print*,'%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'
  print*,'%%%%%%%%%%%%%%%%%%%%% DATA CREATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'
  print*,'%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'
  
  call init_acoustic_problem(forward,nb_elem,DoF,time_scheme,velocity_data,     &
                             density_data,total_length,final_time,alpha,        &
                             bernstein,signal,boundaries,source_loc,receiver_loc)

  data_time_step=forward%n_time_step
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
 
  if (bool_fwi) then
     print*,'%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'
     print*,'%%%%%%%%%%%%%%%%%%%%% FWI %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'
     print*,'%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'

     call init_fwi(fwi,nb_iter_fwi,velocity_ini,density_ini,data_P,data_U,      &
                   nb_elem,DoF,time_scheme,total_length,final_time,alpha,       &
                   bernstein,source_loc,receiver_loc,strategy,scalar_product,   &
                   animation,adjoint_test)

     do i=1,fwi%nb_iter
        print*,'size velocity model',size(fwi%velocity_model)
        fwi%current_iter=i
        print*,'Iteration n°',fwi%current_iter,'/',fwi%nb_iter
        call one_fwi_step(fwi)
     end do
     call free_fwi(fwi)
  end if

  
  !--------------------- Animation ----------------------------------------------
  if (animation.eq.'no') then
     print*,'No animation has been made'
  else if (animation.eq.'model_update') then

     n_frame=nb_iter_fwi

     open(unit=78,file='gnuplot_script/script.gnuplot',action='write')
     write(78,*)'load "gnuplot_script/trace1.gnuplot"'
     write(78,*)'n=',nb_iter_fwi
     write(78,*)'a=',1
     write(78,*)'load "gnuplot_script/trace2.gnuplot"'
     close(78)

     open(unit=79,file='gnuplot_script/trace2.gnuplot',action='write')
     write(79,*)'dt=0.1/n'
     write(79,*)'i=0'
     write(79,*)'set yrange[0:2]'
     write(79,*)'load "gnuplot_script/animate.gnuplot"'
     close(79)

     open(unit=80,file='gnuplot_script/animate.gnuplot',action='write')
     write(80,*) "plot 'Files/VP'.i.'.dat' w l title 'Velocity model'.i"
     write(80,*) "i=i+a"
     write(80,*) "if (i<n) reread"
     close(80)

     call system("gnuplot gnuplot_script/script.gnuplot")
     call system("eog animate.gif")
     
  elseif(animation.eq.'data_forward') then
    
     n_frame=data_time_step

     open(unit=78,file='gnuplot_script/script.gnuplot',action='write')
     write(78,*)'load "gnuplot_script/trace1.gnuplot"'
     write(78,*)'n=',n_frame
     write(78,*)'a=',10
     write(78,*)'load "gnuplot_script/trace2.gnuplot"'
     close(78)

     open(unit=79,file='gnuplot_script/trace2.gnuplot',action='write')
     write(79,*)'dt=0.1/n'
     write(79,*)'i=0'
     write(79,*)'set yrange[-0.5:0.5]'
     write(79,*)'load "gnuplot_script/animate.gnuplot"'
     close(79)

     open(unit=80,file='gnuplot_script/animate.gnuplot',action='write')
     write(80,*) "plot 'Files/FP'.i.'.dat' w l title 'Forward data pressure'.i"
     write(80,*) "i=i+a"
     write(80,*) "if (i<n) reread"
     close(80)

     call system("gnuplot gnuplot_script/script.gnuplot")
     call system("eog animate.gif")
     
     elseif(animation.eq.'fwi_forward') then
        
    n_frame=data_time_step
    open(unit=78,file='gnuplot_script/script.gnuplot',action='write')
     write(78,*)'load "gnuplot_script/trace1.gnuplot"'
     write(78,*)'n=',n_frame
     write(78,*)'a=',10
     write(78,*)'load "gnuplot_script/trace2.gnuplot"'
     close(78)

     open(unit=79,file='gnuplot_script/trace2.gnuplot',action='write')
     write(79,*)'dt=0.1/n'
     write(79,*)'i=0'
     write(79,*)'set yrange[-0.5:0.5]'
     write(79,*)'load "gnuplot_script/animate.gnuplot"'
     close(79)

     open(unit=80,file='gnuplot_script/animate.gnuplot',action='write')
     write(80,*) "plot 'Files/P'.i.'.dat' w l title 'Forward fwi pressure'.i"
     write(80,*) "i=i+a"
     write(80,*) "if (i<n) reread"
     close(80)

     call system("gnuplot gnuplot_script/script.gnuplot")
     call system("eog animate.gif")
     
  elseif(animation.eq.'fwi_backward') then
     
     n_frame=data_time_step
     open(unit=78,file='gnuplot_script/script.gnuplot',action='write')
     write(78,*)'load "gnuplot_script/trace1.gnuplot"'
     write(78,*)'n=',n_frame
     write(78,*)'a=',10
     write(78,*)'load "gnuplot_script/trace2.gnuplot"'
     close(78)

     open(unit=79,file='gnuplot_script/trace2.gnuplot',action='write')
     write(79,*)'dt=0.1/n'
     write(79,*)'i=0'
     write(79,*)'set yrange[-0.2:0.2]'
     write(79,*)'load "gnuplot_script/animate.gnuplot"'
     close(79)

     open(unit=80,file='gnuplot_script/animate.gnuplot',action='write')
     write(80,*) "plot 'Files/QP'.i.'.dat' w l title 'Backward fwi pressure'.i"
     write(80,*) "i=i+a"
     write(80,*) "if (i<n) reread"
     close(80)

     call system("gnuplot gnuplot_script/script.gnuplot")
     call system("eog animate.gif")
  end if

  !------------------------ Free Variables --------------------------------------
  call free_basis_b
  call free_basis_l
  call free_B2L
  call free_L2B
  call free_derive
  
end program main
