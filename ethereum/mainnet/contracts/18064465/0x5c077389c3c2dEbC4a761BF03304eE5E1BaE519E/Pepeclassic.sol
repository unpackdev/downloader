// SPDX-License-Identifier: MIT

/**
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⠻⣝⠯⢯⡽⢭⡻⡝⣯⣛⢿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠊⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⢧⡻⣜⢯⢳⢞⣣⣝⡳⡵⢮⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡐⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠊⠀⠀⠀
⡝⣦⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠡⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡟⣮⢵⢫⡞⣭⢞⡱⣎⢷⣹⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠌⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠔⠁⠀⠀⠀⠀
⡝⣶⢳⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠡⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⡹⢖⣫⠗⣾⣡⢏⡷⣹⢮⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⡠⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⠁⠀⠀⠀⠀⠀⠀
⣛⠶⣋⠾⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢡⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⢧⣛⡽⣬⣛⠶⡭⣞⡱⢧⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠔⠀⠀⠀⠀⠀⠀⠀⠀⠀⡠⠂⠀⠀⠀⠀⠀⠀⠀⠀
⢯⡽⣩⢟⡼⣣⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡟⣮⢵⢺⡱⣎⢯⢳⡭⡽⠃⠀⠀⠀⠀⠀⠀⠀⠀⠠⠊⠀⠀⠀⠀⠀⠀⠀⠀⠠⠊⠀⠀⠀⠀⠀⠀⠀⠀⢀⣰
⡳⣞⡱⣏⡞⡵⣳⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣠⣤⣼⣀⣀⣀⠀⠀⠀⠀⠀⠀⠀⣼⡹⢖⣫⢳⡝⣮⢝⡳⠾⠁⠀⠀⠀⠀⠀⠀⠀⠀⡐⠁⠀⠀⠀⠀⠀⠀⠀⢀⠄⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⡛⡶
⢳⢭⡳⢮⡝⣵⢣⡟⣦⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠄⢀⣤⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣦⣄⡀⣰⢧⣛⡝⣮⢳⡹⣜⢮⡽⠁⠀⠀⠀⠀⠀⠀⠀⢀⠌⠀⠀⠀⠀⠀⠀⠀⢀⠔⠁⠀⠀⠀⠀⠀⠀⠀⢀⣴⣛⠶⣹⢳
⠀⠑⢝⡳⣞⡱⣏⢾⣱⢳⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⠀⠀⠀⠀⠀⠀⠀⠀⠀⣇⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣏⢾⣡⢟⡲⣏⡵⣫⡾⠁⠀⠀⠀⠀⠀⠀⠀⡠⠀⠀⠀⠀⠀⠀⠀⠀⡠⠂⠀⠀⠀⠀⠀⠀⠀⣀⢴⣛⢦⠯⣝⣣⢏
⠀⠀⠈⠳⣎⢷⡹⢶⣙⢮⡽⢄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠆⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣟⢮⡵⣎⠷⣭⠞⡵⠁⠀⠀⠀⠀⠀⠀⠀⠔⠀⠀⠀⠀⠀⠀⠀⡠⠊⠀⠀⠀⠀⠀⠀⠀⣠⠾⣙⢮⢧⣛⠾⣱⢭⡞
⠀⠀⠀⠀⠈⢣⡻⣥⣛⢮⢞⡽⣢⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⡀⠀⠀⠀⠀⠀⠀⠀⠀⢰⠀⠀⠀⠀⢀⣠⣤⣤⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢺⡴⣫⡝⡶⡻⠁⠀⠀⠀⠀⠀⠀⠀⠊⠀⠀⠀⠀⠀⠀⢀⠄⠀⠀⠀⠀⠀⠀⠀⣠⠾⣭⣛⡭⣞⢎⣧⢻⣱⠏⠈
⠀⠀⠀⠀⠀⠀⠑⢧⢏⡞⣮⢓⣧⢳⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⡀⠀⠀⠀⠀⠀⠀⠀⠀⡆⠀⢠⣾⣿⣿⣿⣿⣷⣻⣽⣻⣟⣿⡿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⡳⢧⣝⡳⠁⠀⠀⠀⠀⠀⠀⡐⠁⠀⠀⠀⠀⠀⢀⠔⠁⠀⠀⠀⠀⠀⠀⣠⠾⣭⣛⢦⡳⢽⣸⣋⡶⠋⠁⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠙⣞⡱⣏⢮⡳⢞⣆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠱⠀⠀⠀⠀⠀⠀⠀⠀⢡⠀⢿⣿⣿⣿⣿⣿⣷⣿⣾⣽⣞⣳⣟⣷⡻⣞⡧⣚⠴⣃⠞⣼⣿⣻⢯⣿⣿⣿⣷⣞⠀⠀⠀⠀⠀⠀⢀⠌⠀⠀⠀⠀⠀⠀⡀⠁⠀⠀⠀⠀⠀⢀⡤⣞⡹⣞⡱⣎⢷⣹⢣⠗⠁⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠳⣹⢎⢷⣫⡜⡧⡀⠀⠀⠀⠀⠀⠀⠀⠀⠡⠀⠀⠀⠀⠀⠀⠀⠈⣄⣈⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣿⣿⣧⣷⣼⣬⣾⣾⣿⣿⣿⣿⣿⣿⣿⣿⠇⠀⠀⠀⠀⡠⠂⠀⠀⠀⠀⠀⡠⠊⠀⠀⠀⠀⠀⢀⣴⣛⡼⣱⠯⣜⡳⣝⠮⠊⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⡀⠀⠀⠀⠀⠀⠈⢞⡧⣞⡱⣏⠷⣄⠀⠀⠀⠀⠀⠀⠀⠀⢣⠀⠀⠀⠀⠀⠀⠀⢃⠻⢿⣽⢟⣿⣿⣻⣿⣿⣿⡿⡿⣿⡿⡿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢿⠁⠀⠀⠀⠀⠔⠀⠀⠀⠀⠀⢀⠌⠀⠀⠀⠀⠀⢀⣴⣛⠶⡭⡞⡵⣛⡼⠗⠁⠀⠀⠀⠀⠀⠀⢀⠀⠀⠀
⠀⠀⠀⠀⠀⠈⠢⡀⠀⠀⠀⠀⠀⠑⢯⢵⢫⡝⡞⣦⠀⠀⠀⠀⠀⠀⠀⠀⢂⠀⠀⠀⠀⠀⠀⠘⡀⣼⣿⣸⣿⣿⣿⠛⠳⢿⣻⣿⣵⣯⣷⣻⣼⣷⣿⢿⡻⢯⣿⣿⣿⢿⣿⣟⠟⠀⠀⠀⢠⠊⠀⠀⠀⠀⢀⠔⠁⠀⠀⠀⠀⢀⣴⡛⡶⢭⡳⡽⣱⠏⠋⠀⠀⠀⠀⠀⠀⢀⠀⠂⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠈⠢⡀⠀⠀⠀⠀⠀⠫⣳⢭⣛⡖⢷⡀⠀⠀⠀⠀⠀⠀⠀⢂⠀⠀⠀⠀⠀⠀⣗⢽⢿⣿⣿⣿⣷⣶⣿⣿⣟⣯⣷⡞⡶⣭⣯⣿⣯⣤⣀⣹⣿⣿⣿⣦⡿⡁⠀⠀⠀⡐⠁⠀⠀⠀⠀⡐⠁⠀⠀⠀⠀⣠⡜⣧⢳⡝⣭⢳⡭⠓⠁⠀⠀⠀⠀⠀⢀⠄⠊⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠢⡀⠀⠀⠀⠀⠈⠣⡗⣞⢧⡻⣄⠀⠀⠀⠀⠀⠀⠈⠄⠀⠀⠀⠀⠀⢸⣺⣵⣻⡿⡿⢿⣛⢯⡳⢎⡳⣏⣟⡱⣏⠿⣱⠮⣝⡻⣿⣿⡿⢿⣏⡇⣧⠀⢀⠌⠀⠀⠀⠀⡠⠊⠀⠀⠀⠀⣠⡞⣧⢻⡜⣳⢞⠕⠉⠀⠀⠀⠀⠀⢀⠄⠊⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠀⠀⠀⠀⠙⢮⡳⣝⠮⣧⡀⠀⠀⠀⠀⠀⠈⠄⠀⠀⠀⠀⠘⣎⠿⣟⡿⣿⣷⣭⣾⣍⣋⣵⣭⣴⢯⣼⣯⣓⣻⣜⣳⣑⣎⣽⣥⣼⢾⣹⠠⠂⠀⠀⠀⠠⠊⠀⠀⠀⠀⣠⡞⣧⢻⢬⡳⡽⠋⠁⠀⠀⠀⠀⡀⠔⠊⠀⠀⠀⠀⠀⠀⠀⢀⠤⠒⠁⠀⠀
⠀⠀⠀⠀⠑⠠⡀⠀⠀⠀⠀⠀⠀⠀⠑⢄⠀⠀⠀⠀⠙⡼⣛⡴⣳⠄⠀⠀⠀⠀⠀⠘⡄⠀⠀⢀⠠⢔⣧⠻⣿⣳⢿⣻⣯⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢿⡿⣟⢯⡛⡞⠟⠁⠀⠀⢀⠔⠀⠀⠀⢀⡠⣞⢧⡞⣵⢫⠞⠁⠀⠀⠀⠀⡀⠔⠈⠀⠀⠀⠀⠀⠀⢀⠠⠐⠈⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠑⠄⡀⠀⠀⠀⠀⠀⠀⠑⢄⠀⠀⠀⠈⠳⣹⢖⡻⢦⠀⠀⡠⠄⢐⣚⠨⡍⢒⣼⣏⠎⠉⣿⢿⢿⣿⣽⣿⡾⣭⣯⣞⣿⣳⣿⣞⣷⣻⣭⣿⣾⣿⣯⣐⠉⠀⠀⠀⠔⠁⠀⠀⢀⣴⢫⢗⡭⢶⠹⠊⠀⠀⠀⠀⡀⠔⠈⠀⠀⠀⠀⠀⢀⡠⠔⠊⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠰⠄⡀⠀⠀⠀⠀⠀⠑⠄⠀⠀⠀⠈⢞⡭⣏⠷⡘⣄⣃⠇⢆⣱⢬⣾⡻⠇⢀⣰⢿⡩⡡⠀⠉⠙⠛⢿⠿⣿⣾⡿⡾⠿⠿⠿⡟⣻⣉⢱⣼⣿⣏⠔⡠⢆⠀⠀⢀⣴⢻⡜⣽⡪⠙⠁⠀⠀⠀⡀⠔⠈⠀⠀⠀⠀⠀⡀⠄⠊⠁⠀⠀⠀⠀⠀⠀⢀⠠⠄⠂⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠂⢄⠀⠀⠀⠀⠀⠀⠢⠀⠀⠀⠙⢼⡻⢰⠡⡏⢹⢠⢸⡆⣰⠭⢒⡾⠁⣿⣷⡈⠀⠀⢀⢴⡡⣺⣷⣷⡀⠀⠀⢔⢬⡵⠈⢻⣆⣉⣛⣽⣶⠁⢎⢉⣲⣿⣜⣣⠟⠊⠀⠀⠀⡠⠐⠈⠀⠀⠀⠀⣀⠄⠂⠁⠀⠀⠀⠀⠀⠀⡀⠄⠒⠈⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠢⢄⠀⠀⠀⠀⠈⠢⡀⠀⢀⢃⠃⢆⣷⠘⡂⠆⡗⡘⡀⠀⠀⠀⢿⣿⣿⡄⡰⠁⠈⣷⣻⢵⠃⠸⢄⢀⣵⡿⠀⠀⠀⠙⠈⡡⣾⠣⡘⢂⢆⣿⣽⠂⠁⠀⠀⡠⠐⠁⠀⠀⠀⢀⠤⠒⠁⠀⠀⠀⠀⠀⣀⠠⠐⠈⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠁⠢⢀⠀⠀⠀⠈⠢⡌⣌⡉⠆⣿⠀⡧⠌⢽⡐⠇⠀⠀⠀⢸⣿⣿⣿⡄⠀⣸⡛⣡⢪⡀⠀⣨⣾⡿⠁⠀⠀⠀⠀⣰⣽⠣⡑⢌⠡⣾⠇⢻⡇⡠⠐⠁⠀⠀⢀⠠⠐⠈⠀⠀⠀⠀⢀⠠⠄⠂⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠉⠐⠠⠄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠑⠢⡀⠀⡸⡰⠰⡈⠆⣿⡀⢣⠘⡘⣇⠺⡀⠀⠀⠀⣿⣿⣿⣿⣤⡻⢋⡴⢋⣧⣾⣿⡿⠁⠀⠀⠀⠀⣰⣷⠋⡔⢡⠊⣴⡟⢨⢹⡇⠀⢀⠠⠐⠈⠀⠀⠀⢀⡀⠄⠒⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠁⠐⠠⢄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢁⢣⢃⠣⡘⠰⣿⡇⢸⡐⢡⢻⡐⣃⠀⠀⠀⠸⣿⣿⣿⣿⣶⣋⣴⣿⣿⣿⡿⠁⠀⠀⠀⠀⣰⣿⠃⢎⠰⣁⢣⡿⢡⠢⠸⣿⠂⠁⠀⠀⡀⠤⠐⠈⠁⠀⠀⠀⠀⢀⡀⠤⠀⠂⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠁⠒⠠⢀⠀⠀⠀⠀⠀⠠⢃⠎⢢⠑⡌⢡⣿⡇⠘⡠⢃⠤⣳⠌⡄⠀⠀⠀⣻⣿⣿⣿⣿⣿⣿⣿⣿⣿⠃⠀⠀⠀⠀⣰⡿⢡⢊⠄⠣⢄⣿⢃⠆⡡⢃⣿⠠⠔⠂⠁⠀⠀⠀⢀⠠⠤⠐⠀⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⡠⣤⡔⣶⣒⢯⡻⢵⢫
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠁⠂⠤⢀⡏⡇⢎⠡⢊⠔⡡⣿⢶⠀⡇⢎⠰⢠⢻⡘⡄⠀⠀⠘⣿⣿⣿⣿⣿⣿⣿⣿⠃⠀⠀⠀⢀⣼⡟⡑⢢⠌⣊⠑⣾⡏⡌⢢⠑⣂⢿⠀⣀⠠⠄⠒⠈⠁⠀⠀⠀⠀⠀⠀⠀⣀⣀⣠⢤⡔⣶⣒⢯⠯⣝⢮⣓⡗⣺⡕⣮⢳⠽⣩⢗
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⢰⠱⣈⠒⡉⠆⡅⣿⣻⠀⠗⢨⠑⡂⢆⢳⡜⢄⠀⠀⢹⣿⣿⣿⣿⣿⣿⠃⠀⠀⠀⣠⣾⢋⠔⡡⠒⡌⢄⣿⣿⣇⠑⢢⠑⡄⢺⡀⠀⠀⠀⠀⣀⣀⣠⢤⡔⡶⢎⡿⢭⡳⡽⢬⡳⣝⠶⣹⢎⡟⣼⢣⡗⢾⡱⣞⡱⣏⣏⡗⣫
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡜⣨⣖⣦⡍⡔⢡⢊⣿⡝⡇⢸⢠⢃⠱⡈⢆⡙⣎⢆⠀⠀⢿⣿⣿⣿⣿⠃⠀⠀⢀⣴⡟⢡⠊⡔⢡⠃⡜⣼⣫⡷⣿⡎⢢⠑⡨⣹⡷⣖⢮⢻⣭⢳⣓⢮⡳⡭⢏⡽⢎⡷⡹⢞⣣⢟⡜⣏⡳⢮⡝⡶⣋⡞⣧⢻⣜⣧⣳⣚⡼⠣
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠂⠀⠀⠀⠀⠀⠀⠀⣀⣀⣀⡜⡞⢡⢂⣱⣨⣂⣾⡿⠀⡇⠸⠰⡈⢆⡑⢢⠐⡹⢶⠣⡀⠘⣿⣿⣿⠃⠀⢀⣴⡿⢋⠜⡠⢃⠜⡠⢃⠜⣡⣿⣿⢹⣿⡆⡱⢄⣹⡿⡼⣩⢗⣮⣳⣭⣞⠵⠫⠿⠼⠯⠼⠙⠋⠚⠚⠛⠚⠉⠁⠉⠉⠉⠉⠁⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠅⡗⣈⠛⣼⡛⣽⢿⠁⠀⢧⠀⡕⡌⠢⠜⡠⢃⠔⡊⠽⣕⠄⢻⣿⠃⢀⣴⡿⢋⠔⡉⢆⠱⢌⠢⡑⢬⣖⡾⢿⢿⠠⡙⢷⡌⠰⢸⣯⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡈⣘⡐⢢⠑⠤⡑⢸⠀⠀⠀⣸⠀⠧⢌⠱⣈⠱⡈⢆⡉⢆⠩⢾⢰⠃⣴⡿⢋⠔⡡⢊⠔⣈⠲⡈⢆⣱⣿⢿⠃⢸⣿⡠⢑⠢⡐⢡⢃⠻⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣀⣀⣀⣤⣤⡇⡇⡘⠤⡉⢆⠱⣸⢿⡹⣝⡞⠳⢮⣔⡡⢂⠥⡘⠤⡘⢄⠣⢼⣧⣾⡏⠔⡡⢊⠔⡁⠎⡄⢣⠘⡸⣿⣯⡏⠀⠼⣿⢷⡈⢆⡑⠢⢌⠒⣇⠀⠀⠈⠉⠉⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⣀⢠⠤⡤⢤⡴⢶⣲⣒⡖⢯⡻⡝⣧⣛⡼⣣⢗⡞⣲⢭⡇⡇⠱⣈⠴⣈⣶⣾⡧⠟⣾⣀⠀⠀⠈⠙⢳⣦⠑⡢⢑⠌⣂⣿⠙⡋⠔⡩⣐⠡⢎⠰⢡⠘⡄⠣⠔⣿⣿⠐⠀⠤⢸⣳⣌⠆⠬⡑⠌⡌⢿⠒⠀⠠⠤⠄⢀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⡝⣮⣛⣭⢳⢞⣣⢗⡮⡝⣧⣛⡝⣖⣣⠷⣙⢮⣝⣣⢏⡇⡇⠣⢌⣾⡻⢿⡃⠀⢠⡉⠛⠷⣦⣄⡠⣼⡿⣈⠱⣈⠒⡄⣿⡘⠤⡉⠔⡠⠣⢌⠢⣁⠎⡰⢁⠣⢹⣏⠐⠂⠄⣈⣧⠹⣮⠑⡌⠜⡠⢻⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠁⠀⠒⠂⠀⠤⠤⠀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⣛⢶⡱⣎⢯⢞⡱⣎⢷⡹⣖⡭⣞⡱⣭⢞⡽⣚⠶⠝⠊⢇⣺⣷⠜⢩⠑⠇⣇⡔⠆⠑⠢⢤⣈⠙⡝⣉⠒⡌⠒⡄⢣⠐⣿⠰⠡⠜⡰⢁⠣⢌⠒⡄⢎⠰⡁⢎⣹⣿⠽⣳⠦⣄⣹⡐⠤⢃⠜⡠⠱⢸⡇⠈⠁⠒⠀⠤⠀⢀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠀⠐⠒⠀⠀⠄⠀⠀⠀
⣏⠾⣱⢏⡾⣩⠷⣹⢎⡗⣮⣵⠮⠗⠛⠈⠁⠀⠀⠀⠀⡐⣭⠏⢌⠂⣍⣼⢫⠀⢸⠀⠀⠀⠈⢙⣶⢠⢃⠬⡑⢸⣾⣷⣿⡇⡉⢆⠱⡈⠖⣈⠒⣬⡴⢷⣟⡿⢯⠻⣄⠀⠉⠳⢟⡇⢣⡘⢄⠣⣙⠤⣧⢀⡀⠀⠀⠀⠀⠀⠀⠉⠁⠒⠀⠤⠀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⣎⠿⣱⢎⡷⣭⡳⠝⠚⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣣⠉⢎⠄⣃⡞⢸⢸⡇⠈⡿⣶⣄⣠⢺⢏⠰⡈⢆⠡⢃⠍⣩⣷⡇⠱⡈⢆⡑⠎⠤⡉⢽⣉⠣⡐⠰⢂⡉⡇⠈⠂⢄⠀⢹⢢⠘⡄⢣⠸⣧⣹⡄⠈⠁⠒⠠⢀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠀⠒⠀⠤⢀⡀⠀⠀⠀⠀⠀⠀⠀⠀
⡞⠽⠓⠋⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠠⠂⠁⠈⡆⠈⢞⡭⠲⡘⣆⢷⠀⢱⢨⢻⡳⣿⠾⢡⡑⢌⡑⢊⢔⣼⣿⣧⠱⡈⢆⡘⢌⠢⡑⠌⣧⢂⠅⢣⣁⣦⣽⠢⠀⠀⠈⢚⡇⢎⠰⡁⢎⠻⣧⣟⡗⡦⣄⡀⠀⠀⠁⠐⠠⠄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠁⠐⠂⠠⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⠔⠈⠀⠀⠀⠀⠀⠸⣒⡁⠀⢀⣷⠻⠞⢰⢉⠆⡒⢰⡐⠌⠆⡌⢢⠘⡄⣾⢿⢸⣿⡠⢑⠢⡘⢄⠣⣘⠰⡈⡍⢫⠑⡌⣸⣿⠀⠀⠑⢄⢘⡏⢢⠑⡌⢢⢁⢻⣟⠺⢵⢣⣏⢟⡲⣤⣀⠀⠀⠀⠉⠐⠢⠄⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠠⠐⠁⠀⠀⠀⠀⠀⠀⠀⡀⠐⠁⠈⠔⠫⠝⣆⠄⡼⣀⠎⡰⠡⡘⢌⡱⢈⠆⡱⣸⡿⢸⣹⣿⢧⡌⢆⡑⢊⠴⣀⠣⠜⡠⢃⠜⡰⠸⣿⡀⠀⠀⠀⠙⣇⢣⠘⡄⠣⠌⡌⢿⠀⠀⠈⠚⠭⣳⣓⢮⡝⡶⢤⣄⡀⠀⠀⠀⠈⠐⠂⠄⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⡀⠔⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⡠⠊⠀⠀⠀⠀⠀⠀⠀⣸⣌⡑⠧⡘⢄⠣⡘⢄⠢⡁⣎⣼⣟⠣⡉⠜⣿⡿⣿⣤⡘⢄⠒⡄⢣⠘⡡⢊⠔⡡⠑⣿⠈⢄⠀⠀⠀⢸⠄⠣⢌⠱⢨⠐⡩⡗⢄⠀⠀⠀⠀⠉⠚⢝⣞⡳⢮⡝⢧⢦⣄⡀⠀⠀⠀⠀⠈⠁⠂⠤⢀⡀⠀⠀⠀
⠀⠀⠀⢀⠠⠂⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠔⠈⠀⠀⠀⠀⠀⠀⠀⢀⠊⢰⣷⣌⢢⠑⡌⢢⠑⡌⣢⣿⢽⠗⣡⠂⡍⠒⣿⣟⣿⡿⠷⣈⠒⡌⢢⠑⢢⡁⢎⠰⠡⣿⠀⠀⠑⢄⠀⠈⡬⠑⠚⠒⠓⠊⠁⡍⠀⠈⠂⢄⠀⠀⠀⠀⠈⠙⠳⢺⡝⣮⢞⡹⣏⠶⣤⢀⠀⠀⠀⠀⠀⠈⠁⠒⠠
⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⠔⠁⠀⠀⠀⠀⠀⠀⠀⠀⡐⠁⠀⢸⣷⣿⡷⡪⣔⡡⣪⣾⡿⠓⡅⡊⠤⣑⡨⢑⠸⣿⡍⡐⢢⢁⠎⡰⢁⠎⣡⠘⡄⢣⡱⣿⠀⠀⠀⠀⠁⡰⢋⡍⢫⡙⢍⡓⢲⣁⣀⡀⠀⠀⠈⠂⢄⠀⠀⠀⠀⠀⠈⠓⠮⣳⢭⡻⣜⣫⣝⡳⢦⡄⡀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡠⠊⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠊⠀⠀⠀⠀⢿⡾⣻⡷⣌⢯⣫⢫⠄⢣⠐⡡⠒⡌⢷⣈⡒⢹⣿⣔⠡⢊⠔⡡⢊⠔⡄⢣⠘⣴⢟⣿⠀⠀⠀⠀⠀⢯⢅⢻⡔⢌⡒⠬⣹⣿⣿⣿⡆⠀⠀⠀⠀⠈⠂⢄⠀⠀⠀⠀⠀⠀⠁⠻⢼⡱⢮⣝⣣⠟⣭⢳⠦⣤⣀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠔⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠔⠁⠀⠀⠀⠀⠀⠘⣮⢻⡶⢀⠆⡩⢁⠎⡄⢣⠰⢡⠘⣸⢇⣹⣦⡹⣿⣷⣅⢊⠔⡡⢊⠔⡡⢚⣳⣧⠿⠀⠀⠀⠀⠀⠀⠣⣎⡗⣸⢅⢓⡜⠈⣽⣿⡟⠀⡀⠀⠀⠀⠀⠀⠈⠂⢄⠀⠀⠀⠀⠀⠀⠈⠑⠪⢧⡻⣜⡫⣗⢳⣎
⠀⠀⠀⠀⠀⠀⠀⡠⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⠊⠀⠀⠀⠀⠀⠀⠀⠀⢣⠕⡵⢎⠰⡑⢌⠒⡌⢢⠑⡌⢒⢹⡘⢦⢉⠛⢌⠛⢿⣿⣶⣷⣾⡶⣿⡟⣿⠃⠀⠱⡀⠀⠀⠀⠀⠀⣿⢐⣿⠤⡟⠀⠸⣿⠿⠃⠀⠈⠢⡀⠀⠀⠀⠀⠀⠀⠈⠂⢄⠀⠀⠀⠀⠀⠀⠀⠉⠃⠟⡼⣓⢮
⠀⠀⠀⠀⠀⡠⠊⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠔⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⡬⡘⢦⠃⡜⠠⢍⡰⠁⢎⠰⡁⢾⣿⡀⠎⢌⠢⡉⠆⡌⢓⠻⢼⣳⣧⠿⡽⠀⠀⠀⠐⡀⠀⠀⠀⠀⣿⣾⣿⠷⡗⠄⠀⠀⠀⠀⠀⠀⠀⠀⠐⢄⠀⠀⠀⠀⠀⠀⠀⠈⠂⢄⠀⠀⠀⠀⠀⠀⠀⠈⠙⠺
⠀⠀⠀⠐⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⠊⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡐⢱⢡⠢⡑⢨⠑⢢⠐⣉⠢⡑⢌⢸⡏⢣⠘⡄⢃⠜⡰⠘⠤⡉⢆⡐⣯⢿⠇⠀⠀⠀⠀⠈⠄⠀⠀⠀⣿⣿⣿⡂⠀⠈⠢⡀⠀⠀⠀⠀⠀⠀⠀⠀⠁⠠⡀⠀⠀⠀⠀⠀⠀⠀⠈⠂⢄⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠔⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⠁⠈⣆⠱⡈⢆⡉⢆⠱⢠⠃⡜⢠⢺⠅⣂⠣⡘⠄⢎⠰⡉⢆⡑⠢⢌⣿⡻⠀⠀⠀⠀⠀⠀⠈⢄⠀⠀⣿⣿⣿⠀⠀⠀⠀⠈⠢⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠢⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠂⢄⡀⠀⠀⠀

Pepe Classic $PEPEC

In the year 2005, Matt Furie created the comic book "Boy's Club", which featured a green frog named Pepe. Pepe quickly became a popular internet meme, and his image was used to express a wide range of emotions and ideas. In the early days, Pepe was mostly used in a positive way, but as time went on, he was increasingly used in a more negative way.

In 2016, Pepe was appropriated by the alt-right movement, and he was used to spread hateful and racist messages. This led to Pepe being banned from many social media platforms. However, Pepe's fans refused to let him be used for hate, and they continued to use his image in a positive way.

In 2023, a group of Pepe fans created Pepe Classic, a meme coin that is based on the original Pepe the Frog meme. Pepe Classic is a deflationary token, meaning that the total supply of tokens is limited. This makes Pepe Classic a scarce asset, which could potentially increase its value over time. Pepe Classic is also a community-driven project, meaning that the decisions about its future are made by the Pepe community. This ensures that Pepe Classic remains true to its roots as a meme coin, and that it is always evolving to meet the needs of its users.


Socials:

Telegram: https://t.me/PepeCToken
Website: https://pepectoken.pro/
Twitter: https://twitter.com/PepeClassic_ETH


*/

pragma solidity 0.8.21;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract Pepeclassic is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) public isWalletSizeExempt;
    mapping (address => bool) public isTxAmountExempt;
    mapping (address => bool) public marketPair;
    address payable private _taxWallet;
    uint256 firstBlock;

    uint256 private _initialBuyTax=20;
    uint256 private _midBuyTax=5;
    uint256 private _initialSellTax=30;
    uint256 private _midSellTax=15;
    uint256 private _finalBuyTax=1;
    uint256 private _finalSellTax=1;

    uint256 private _midBuyTaxAt=10;
    uint256 private _reduceBuyTaxAt=35;

    uint256 private _midSellTaxAt=20;
    uint256 private _reduceSellTaxAt=40;
    uint256 private _preventSwapBefore=15;
    uint256 private _buyCount=0;

    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 420690000000 * 10**_decimals;
    string private constant _name = unicode"Pepe Classic";
    string private constant _symbol = unicode"PEPEC";
    uint256 public _maxTxAmount =   8413800000 * 10**_decimals;
    uint256 public _maxWalletSize = 8413800000 * 10**_decimals;
    uint256 public _taxSwapThreshold= 1262070000 * 10**_decimals;
    uint256 public _maxTaxSwap= 8413800000 * 10**_decimals;

    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;

    event MaxTxAmountUpdated(uint _maxTxAmount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () {

        _taxWallet = payable(_msgSender());
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;

        isTxAmountExempt[owner()] = true;
        isTxAmountExempt[address(uniswapV2Pair)] = true;
        isTxAmountExempt[address(this)] = true;

        isWalletSizeExempt[owner()] = true;
        isWalletSizeExempt[address(uniswapV2Pair)] = true;
        isWalletSizeExempt[address(this)] = true;
        
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function automatedMarketMaker(address addr) public onlyOwner {
        marketPair[addr] = true;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount=0;
        if (marketPair[from] && to != address(this)){ 
            require(tx.origin == to);
            }
        if (from != owner() && to != owner()) {
            taxAmount = amount.mul((_buyCount> _reduceBuyTaxAt)? _finalBuyTax: ((_buyCount> _midBuyTaxAt)? _midBuyTax: _initialBuyTax)).div(100);

            if (!isTxAmountExempt[from] && !isTxAmountExempt[to]) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");

                if (firstBlock + 3  > block.number) {
                    require(!isContract(to));
                }
                _buyCount++;
            }

            if (!isWalletSizeExempt[to]) {
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
            }

            if(marketPair[to] && from!= address(this) ){
                taxAmount = amount.mul((_buyCount> _reduceSellTaxAt)? _finalSellTax: ((_buyCount> _midSellTaxAt)? _midSellTax: _initialSellTax)).div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && marketPair[to] && swapEnabled && contractTokenBalance>_taxSwapThreshold && _buyCount>_preventSwapBefore) {
                swapTokensForEth(min(amount,min(contractTokenBalance,_maxTaxSwap)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }

        if(taxAmount>0){
          _balances[address(this)]=_balances[address(this)].add(taxAmount);
          emit Transfer(from, address(this),taxAmount);
        }
        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }


    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function setIsTxAmountExempt(address addr, bool exempt) external onlyOwner {
        isTxAmountExempt[addr] = exempt;
    }

    function setIsWalletSizeExempt(address addr, bool exempt) external onlyOwner {
        isWalletSizeExempt[addr] = exempt;
    }

    function isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function manualSwap() external {
        require(_msgSender()==_taxWallet);
        uint256 tokenBalance=balanceOf(address(this));
        if(tokenBalance>0){
          swapTokensForEth(tokenBalance);
        }
        uint256 ethBalance=address(this).balance;
        if(ethBalance>0){
          sendETHToFee(ethBalance);
        }
    }

    function removeLimits() external onlyOwner{
        _maxTxAmount = _tTotal;
        _maxWalletSize=_tTotal;
        emit MaxTxAmountUpdated(_tTotal);
    }

    function sendETHToFee(uint256 amount) private {
        _taxWallet.transfer(amount);
    }

    function enableTrading() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        marketPair[address(uniswapV2Pair)] = true;
        isWalletSizeExempt[address(uniswapV2Pair)] = true;
        isTxAmountExempt[address(uniswapV2Pair)] = true;
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        swapEnabled = true;
        tradingOpen = true;
        firstBlock = block.number;
    }

    receive() external payable {}
}