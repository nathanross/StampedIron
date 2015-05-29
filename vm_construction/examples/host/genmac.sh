#!/bin/bash
printf 'AA:BB:CC:DD:%02X:%02X\n' $((RANDOM%256)) $((RANDOM%256))
