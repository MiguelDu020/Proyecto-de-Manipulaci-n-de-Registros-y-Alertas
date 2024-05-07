.data
	parsing_rules: .asciiz "dirección del archivo"
	data_file: .asciiz "dirección del archivo"
	nombre_archivo_alerts: .asciiz "dirección del archivo donde se va a Guardar"
	nombre_archivo_reporte: .asciiz "dirección del archivo donde se va a Guardar"

	buffer: .space 256
	tabla_logs:  .space 800       # Espacio para almacenar 200 registros (4 bytes por registro)
	tabla_logs_end:
	tabla_logs1: .word 0:4   
	tabla_alerts:  .space 800     # Espacio para almacenar 200 registros (4 bytes por registro)
	tabla_alerts_end:
	tabla_alerts1: .word 0:4
	alarmas: .asciiz "Alarma1 Alarma2 Alarma3"
	not_found_msg: .asciiz "Elemento no encontrado"
	longitud_alarmas: .word 3
	longitud_reporte:   .word 0   # Declaración de la variable longitud_reporte con valor inicial 0
	contenido_reporte:   .asciiz "Este es el contenido del reporte"



.text 

	main:
		jal leer_archivo            # Llamar a la función leer_archivo
		jal extraer_datos_archivo_data  # Llamar a la función extraer_datos_archivo_data
		jal ordenar_tabla_logs        # Llamar a la función ordenar_tabla_logs
		jal eliminar_registros_duplicados   # Salto a la etiqueta eliminar_registros_duplicados
		jal comparar_reglas_con_logs
		la $a0, alarmas              # Cargar la dirección de la cadena de caracteres con las alarmas generadas
		lw $a1, longitud_alarmas      # Cargar 
		jal generar_archivo_alerts
		la $a0, tabla_logs      # Cargar el puntero a la tabla_logs en $a0
		la $a0, not_found_msg    # Cargar la dirección de la cadena de caracteres con el mensaje de no encontrado
		jal buscar_por_usuario  # Llamada a la función buscar_por_usuario
		jal generar_archivo_reporte # Llamada a la función generar_archivo_reporte
		
		
	leer_archivo:
   		# Procedimiento de apertura del archivo
    		li $v0, 13                 # Cargar el código de la llamada al sistema "open"
    		la $a0, parsing_rules      # Cargar la dirección del nombre del archivo en $a0
    		li $a1, 0                  # Modo de apertura: solo lectura
    		li $a2, 0                  # Permisos de archivo: valor predeterminado
    		syscall                    # Abrir el archivo

    		move  $a1, $v0               # Mover el descriptor de archivo a $a1
    		li $v0, 3                  # Cargar el código de la llamada al sistema "read"
    		la $a0, buffer             # Cargar la dirección del buffer de lectura
    		li $a2, 256                # Tamaño del buffer
    		syscall                    # Leer el contenido del archivo en el buffer

		# Imprimir el contenido del archivo
    		move $a0, $v0               # Mover el resultado de la llamada al sistema "read" a $a0
    		li $v0, 4                  # Cargar el código de la llamada al sistema "print_string"
    		la $a0, buffer               # Imprimir la cadena de caracteres almacenada en el buffer
    		li $v0, 4 
    		syscall
    		li $v0, 10
 
    		# Finalizar el procedimiento
    		jr $ra



	extraer_datos_archivo_data:
		# Procedimiento para extraer datos del archivo data
    		li $v0, 13                 # Cargar el código de la llamada al sistema "open"
    		la $a0, data_file          # Cargar la dirección del nombre del archivo en $a0
    		li $a1, 0                  # Modo de apertura: solo lectura
    		li $a2, 0                  # Permisos de archivo: valor predeterminado
    		syscall                    # Abrir el archivo

    		move $a1, $v0               # Mover el descriptor de archivo a $a1
    		li $v0, 3                  # Cargar el código de la llamada al sistema "read"
    		la $a0, buffer             # Cargar la dirección del buffer de lectura
    		li $a2, 256                # Tamaño del buffer
    	                   # Leer el contenido del archivo en el buffer

   	ordenar_tabla_logs:
    		li $t0, 0                     # Inicializar índice externo i
   		li $t1, 0                     # Inicializar índice interno j
    		lw $t2, tabla_logs            # Cargar la dirección base de la tabla de logs en $t2
    		li $t3, 10                    # Cargar la cantidad de registros en la tabla (ajustar según necesidad)

		outer_loop:			#Se sigue ejecitando mientras el indice $t0 sea menor que los registros
    		addi  $t4, $t0, 1              # Incrementar el índice externo i

    			inner_loop:
        		add $t5, $t2, $t1         # Calcular la dirección del elemento actual en la tabla de logs
        		lw $t6, 0($t5)            # Cargar el valor del elemento actual
        		add $t7, $t2, $t4         # Calcular la dirección del siguiente elemento en la tabla de logs
        		lw $t8, 0($t7)            # Cargar el valor del siguiente elemento

        		ble $t6, $t8, no_swap     # Comprobar si los elementos están en orden ascendente
        		sw $t8, 0($t5)            # Intercambiar los elementos
        		sw $t6, 0($t7)

    			no_swap:
        		addi $t1, $t1, 4          # Incrementar el índice interno j
        		blt $t1, $t3, inner_loop  # Comprobar si se ha recorrido toda la tabla
			addi $t0, $t0, 1              # Incrementar el índice externo i
		blt $t0, $t3, outer_loop      # Comprobar si se ha completado el ordenamiento para todos los elementos
		jr $ra                        # Retornar al punto de retorno
		
	eliminar_registros_duplicados:
  
  		li $t0, 0                      # Inicializar índice externo i
		li $t1, 1                      # Inicializar índice interno j
 		lw $t2, tabla_alerts           # Cargar la dirección base de la tabla de alertas en $t2
		li $t3, 10                     # Cargar la cantidad de registros en la tabla (ajustar según necesidad)

    		loop:
        	add $t4, $t2, $t0          # Calcular la dirección del elemento actual en la tabla de alertas
        	lw $t5, 0($t4)             # Cargar el valor del elemento actual
        	add $t6, $t2, $t1          # Calcular la dirección del siguiente elemento en la tabla de alertas
        	lw $t7, 0($t6)             # Cargar el valor del siguiente elemento

        	beq $t5, $t7, remove       # Comprobar si los elementos son iguales y deben eliminarse

        	addi $t0, $t0, 1           # Incrementar el índice externo i
        	addi $t1, $t1, 1           # Incrementar el índice interno j

        	blt $t1, $t3, loop         # Comprobar si se ha recorrido toda la tabla

        	jr $ra                     # Retornar al punto de retorno
        	
        	remove:
        	addi $t1, $t1, 1           # Incrementar el índice interno j
        	sw $t7, 0($t4)             # Eliminar el elemento duplicado (sobrescribir con el siguiente elemento)

        	blt $t1, $t3, loop         # Comprobar si se ha recorrido toda la tabla

        	jr $ra                     # Retornar al punto de retorno
       
       comparar_reglas_con_logs:
       
    		
    		li $t0, 0                    # Inicializar índice i
    		lw $t1, tabla_logs           # Cargar la dirección base de la tabla de logs en $t1
    		li $t2, 10                   # Cargar la cantidad de registros en la tabla 

    		loop1:
        	add $t3, $t1, $t0        # Calcular la dirección del elemento actual en la tabla de logs
        	lw $t4, 0($t3)           # Cargar el valor del elemento actual (IP)
        	add $t5, $t2, $t1          # Calcular la dirección del siguiente elemento en la tabla de alertas
        	lw $t6, 0($t5)             # Cargar el valor del siguiente elemento

        	addi $t0, $t0, 1           # Incrementar el índice externo i

        	blt $t1, $t3, loop         # Comprobar si se ha recorrido toda la tabla

        	jr $ra                     # Retornar al punto de retorno
        	
	generar_archivo_alerts:
		li $v0, 13                   # Cargar el código de la llamada al sistema para abrir un archivo (syscall 13)
    		li $a1, 9                    # Cargar el modo de apertura del archivo (9 para crear y escribir)
    		li $a2, 0                    # Cargar los permisos del archivo (0 para permisos predeterminados)
    		la $a0, nombre_archivo_alerts # Cargar la dirección del nombre del archivo en $a0
    		syscall                      # Llamar al sistema para abrir o crear el archivo

    		move $s0, $v0                # Guardar el descriptor de archivo en $s0

    		move $a0, $s0                # Cargar el descriptor de archivo en $a0
    		la $a1, alarmas              # Cargar la dirección de la cadena de caracteres con las alarmas generadas
    		lw $a2, longitud_alarmas     # Cargar el valor de longitud_alarmas en $a2
    		li $v0, 15                   # Cargar el código de la llamada al sistema para escribir en el archivo (syscall 15)
    		syscall                      # Llamar al sistema para escribir en el archivo

    		li $v0, 16                   # Cargar el código de la llamada al sistema para cerrar un archivo (syscall 16)
    		move $a0, $s0                # Cargar el descriptor de archivo en $a0
    		                      # Llamar al sistema para cerrar el archivo

    		jr $ra                       # Retornar al punto de retorno
    		
	buscar_por_ip:
   
    		li $t0, 0                    # Inicializar índice i
    		lw $t1, tabla_logs           # Cargar la dirección base de la tabla de logs en $t1
    		li $t2, 10                   # Cargar la cantidad de registros en la tabla 
    		loop2:
    		
        	add $t3, $t1, $t0        # Calcular la dirección del elemento actual en la tabla de logs
        	lw $t4, 0($t3)           # Cargar el valor del elemento actual (IP)

        	beq $t4, $a1, found      # Comprobar si la IP coincide con la buscada

        	addi $t0, $t0, 1         # Incrementar el índice i

        	blt $t0, $t2, loop       # Comprobar si se ha recorrido toda la tabla

        	# Si no se encuentra la IP
        	li $v0, 4                # Cargar el código de la llamada al sistema para imprimir una cadena de caracteres (syscall 4)
        	la $a0, not_found_msg    # Cargar la dirección de la cadena de caracteres con el mensaje de no encontrado
        	               # Llamar al sistema para imprimir el mensaje

        	jr $ra                   # Retornar al punto de retorno

    		found:
        	# Si se encuentra la IP
        	lw $t5, 4($t3)           # Cargar otro valor relacionado con el elemento actual en la tabla de logs
    		add $t6, $t4, $t5         # Realizar una operación aritmética con los valores cargados

    	
    		li $v0, 1                # Cargar el código de la llamada al sistema para imprimir un entero (syscall 1)
    		move $a0, $t6            # Cargar el valor a imprimir en el registro de argumento $a0
    		                  # Llamar al sistema para imprimir el valor

        	jr $ra                   # Retornar al punto de retorno
        	
	buscar_por_usuario:
    		# Guardar los registros necesarios en la pila
    		addi $sp, $sp, -8      # Reservar espacio en la pila
    		sw $ra, 0($sp)         # Guardar el registro de retorno en la pila
    		sw $a0, 4($sp)         # Guardar el puntero a la tabla_logs en la pila

    		# Cargar los argumentos en registros
    		lw $t0, 4($sp)         # Cargar el puntero a la tabla_logs en $t0
    		lw $a1, 8($sp)         # Cargar el usuario_buscado en $a1

    		# Recorrer la tabla de logs en busca del usuario
    		la $t1, tabla_logs     # Cargar la dirección base de la tabla de logs en $t1
    		li $t2, 0              # Inicializar el contador de registros encontrados en 0

    		loop3:
        	lw $t3, 0($t1)     # Cargar el valor del registro actual en $t3 (asumiendo que el registro es un entero)
        	beq $t3, $a1, found1    # Comparar el valor del registro actual con el usuario buscado
        	addiu $t1, $t1, 4  # Incrementar la dirección de la tabla de logs
        	addiu $t2, $t2, 1  # Incrementar el contador de registros encontrados
        	j loop             # Saltar al siguiente registro

    		found1:
   		# Si se encuentra el usuario
    		lw $t5, 4($t3)           # Cargar otro valor relacionado con el elemento actual en la tabla de logs
    		add $t6, $t4, $t5         # Realizar una operación aritmética con los valores cargados

   		 
    		li $v0, 1                # Cargar el código de la llamada al sistema para imprimir un entero (syscall 1)
    		move $a0, $t6            # Cargar el valor a imprimir en el registro de argumento $a0
    		                 # Llamar al sistema para imprimir el valor

    		jr $ra    
		    		lw $ra, 0($sp)         # Restaurar el registro de retorno desde la pila
    		addi $sp, $sp, 8       # Liberar el espacio de la pila

    		jr $ra                # Retornar al punto de retorno

	generar_archivo_reporte:
  		li $v0, 13                   # Cargar el código de la llamada al sistema para abrir un archivo (syscall 13)
  		li $a1, 1                    # Cargar el modo de apertura del archivo (1 para escritura)
  		li $a2, 0                    # Cargar los permisos del archivo (0 para permisos predeterminados)
  		la $a0, nombre_archivo_reporte  # Cargar la dirección del nombre del archivo en $a0
 		syscall                      # Llamar al sistema para abrir el archivo

 		 move $s0, $v0                # Guardar el descriptor de archivo en $s0
		# Escribir en el archivo
  		li $v0, 15                   # Cargar el código de la llamada al sistema para escribir en un archivo (syscall 15)
 		 move $a0, $s0                # Cargar el descriptor de archivo en $a0
 		la $a1, contenido_reporte    # Cargar la dirección del contenido del reporte en $a1
		lw $a2, longitud_reporte     # Cargar el valor de longitud_reporte en $a2
  		syscall                      # Llamar al sistema para escribir en el archivo

  		# Cerrar el archivo
  		li $v0, 16                   # Cargar el código de la llamada al sistema para cerrar un archivo (syscall 16)
  		move $a0, $s0                # Cargar el descriptor de archivo en $a0
  		syscall                      # Llamar al sistema para cerrar el archivo


  		li $v0, 16                   # Cargar el código de la llamada al sistema para cerrar un archivo (syscall 16)
 		move $a0, $s0                # Cargar el descriptor de archivo en $a0
  		                      # Llamar al sistema para cerrar el archivo

  		jr $ra                       # Retornar al punto de retorno
