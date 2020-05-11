cmake_minimum_required(VERSION 2.8.9)
project(uart)

#Bring the headers, such as Student.h into the project
#include_directories(include)

#Can manually add the sources using the set command as follows:
set(RX_SOURCES Rx.c)
set(TX_SOURCES Tx.c)

#However, the file(GLOB...) allows for wildcard additions:
file(GLOB RX_SOURCES "Rx.c")
file(GLOB TX_SOURCES "Tx.c")

add_executable(Rx ${RX_SOURCES})
add_executable(Tx ${TX_SOURCES})
