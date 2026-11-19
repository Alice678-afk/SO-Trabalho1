#!/bin/bash

echo "ola" > /tmp/treino.txt
antes=$(sha256sum /tmp/treino.txt | awk '{print $1}')
echo "outra coisa" > /tmp/treino.txt
depois=$(sha256sum /tmp/treino.txt | awk '{print $1}')

if [[ $antes != $depois ]]; then

 echo "O ficheiro mudou"
fi
