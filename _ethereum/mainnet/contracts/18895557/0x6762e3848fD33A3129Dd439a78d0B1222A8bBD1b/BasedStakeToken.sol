// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2023 https://based.foundation
pragma solidity ^0.8.23;

/**
 * ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬
 * ╬╬╬██████████╬╬╬╬╬╬╬╬╬╬╬╣████████╬╬╬╬╬╬╬╬╬████████╬╬╬╬╬╬╬████████████╬╬╬██████████╬╬╬╬╬╬╬
 * ╬╣█╬╬╬╬╬╬╬╬╬╬██╬╬╬╬╬╬╬╬╣█╬╬╬╬╬╬╬╣█╬╬╬╬╬╬██╬╬╬╬╬╬╬╬██╬╬╬╣█╬╬╬╬╬╬╬╬╬╬╬╣█╣█╬╬╬╬╬╬╬╬╬╬██╬╬╬╬╬
 * ╬╬█╬╬╬╬╬╬╬╬╬╬╬╬██╬╬╬╬╬╬╬█╬╬╬╬╬╬╬╬█╬╬╬╬╣█╬╬╬╬╬╬╬╬╬╬╬╬██╬╣█╬╬╬╬╬╬╬╬╬╬╬╣█╣█╬╬╬╬╬╬╬╬╬╬╬╬██╬╬╬
 * ╬╣█╬╬╬╬╬╬╬╬╬╬╬╬╬╬█╬╬╬╬╬█╬╬╬╬╬╬╬╬╬█╬╬╬╣█╬╬╬╬╬╬╬█╬╬╬╬╬╬█╬╣█╬╬╬╬╬╬╬╬╬╬╬╣█╣█╬╬╬╬╬╬╬╬╬╬╬╬╬██╬╬
 * ╬╣█╬╬╬╬╬╣███╬╬╬╬╬█╬╬╬╬╣█╬╬╬╬╬╬╬╬╬╣█╬╬╣█╬╬╬╬╬╫█╣█╬╬╬╬╬█╬╣█╬╬╬╬╬╫██████╬╣█╬╬╬╬╬╫██╬╬╬╬╬╣█╬╬
 * ╬╣█╬╬╬╬╬╣█╬█╬╬╬╬╬█╬╬╬╬╣█╬╬╬╬╬╬╬╬╬╬█╬╬╣█╬╬╬╬╬╣█╣█╬█████╬╣█╬╬╬╬╬╣█╬╬╬╬╬╬╣█╬╬╬╬╬╫█╬█╬╬╬╬╣█╬╬
 * ╬╣█╬╬╬╬╬╣█╬█╬╬╬╬╬█╬╬╬╬╬█╬╬╬╬█╬╬╬╬╬█╬╬╣█╬╬╬╬╬╬███╬╬╬╬╬╬╬╣█╬╬╬╬╬╣█╬╬╬╬╬╬╣█╬╬╬╬╬╫█╬█╬╬╬╬╣█╬╬
 * ╬╣█╬╬╬╬╬╬██╬╬╬╬╬█╬╬╬╬╣█╬╬╬╬█╬█╬╬╬╬╣█╬╬██╬╬╬╬╬╬╬╬██╣╬╬╬╬╣█╬╬╬╬╬╬██████╬╣█╬╬╬╬╬╫█╬█╬╬╬╬╣█╬╬
 * ╬╣█╬╬╬╬╬╬╬╬╬╬╫██╬╬╬╬╬╣█╬╬╬╬█╬█╬╬╬╬╬█╬╬╬╣██╬╬╬╬╬╬╬╬╬███╬╣█╬╬╬╬╬╬╬╬╬╬╬██╣█╬╬╬╬╬╫█╬█╬╬╬╬╣█╬╬
 * ╬╣█╬╬╬╬╬╬╬╬╬╬╬╬╬██╬╬╬╬█╬╬╬╬█╬█╬╬╬╬╬█╬╬╬╬╬╬███╬╬╬╬╬╬╬╬╬█╣█╬╬╬╬╬╬╬╬╬╬╬██╣█╬╬╬╬╬╫█╬█╬╬╬╬╣█╬╬
 * ╬╣█╬╬╬╬╬╣██╬╬╬╬╬╬╣█╬╣█╬╬╬╬╬█╬█╬╬╬╬╬╣█╬╬╬╬╬╬╬╬██╬╬╬╬╬╬╬█╬█╬╬╬╬╬╣██████╬╣█╬╬╬╬╬╫█╬█╬╬╬╬╣█╬╬
 * ╬╣█╬╬╬╬╬╣█╬█╬╬╬╬╬╬█╬╣█╬╬╬╬╬█╬█╬╬╬╬╬╬█╬█████████╬╬╬╬╬╬╬█╣█╬╬╬╬╬╣█╬╬╬╬╬╬╣█╬╬╬╬╬╫█╬█╬╬╬╬╣█╬╬
 * ╬╣█╬╬╬╬╬╣█╬█╬╬╬╬╬╬█╬╬█╬╬╬╬╬╬█╬╬╬╬╬╬╬█╬█╬╬╬╬╬╣█╬█╬╬╬╬╬╬█╬█╬╬╬╬╬╣█╬╬╬╬╬╬╣█╬╬╬╬╬╫█╬█╬╬╬╬╣█╬╬
 * ╬╣█╬╬╬╬╬╣█╬█╬╬╬╬╬╬█╬╬█╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣██╬╬╬╬╬╣█╬█╬╬╬╬╬╬█╣█╬╬╬╬╬╣██████╬╣█╬╬╬╬╬╫█╬█╬╬╬╬╣█╬╬
 * ╬╣█╬╬╬╬╬╣██╬╬╬╬╬╬╬█╬█╬╬╬╬╬╬╬██╬╬╬╬╬╬╬██╬╬╬╬╬╬███╬╬╬╬╬╬█╣█╬╬╬╬╬╬╬╬╬╬╬╬█╬█╬╬╬╬╬╣██╬╬╬╬╬╣█╬╬
 * ╬╣█╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣█╬█╬╬╬╬╬╬█╬╣█╬╬╬╬╬╬█╬█╬╬╬╬╬╬╬╬╬╬╬╬╬█╣╬█╬╬╬╬╬╬╬╬╬╬╬╬█╬█╬╬╬╬╬╬╬╬╬╬╬╬╬██╬╬
 * ╬╬█╬╬╬╬╬╬╬╬╬╬╬╬╬██╣╬█╬╬╬╬╬╬█╬╬█╬╬╬╬╬╬╣█╬██╬╬╬╬╬╬╬╬╬╬██╬╣█╬╬╬╬╬╬╬╬╬╬╬╬█╬█╬╬╬╬╬╬╬╬╬╬╬╬██╬╬╬
 * ╬╬██████████████╬╬╣╬███████╬╬╣█████████╬╬╬███████████╬╬╬██████████████╬█████████████╬╬╬╬╬
 * ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╫╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬
 * ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▌▓▓▓╫▀▀╬╬╬╣╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬
 * ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬██▓Ñ╬▄▓▓▓███▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬
 * ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▓██▀╠▄▓▓▓▓▓▒≡█████▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬
 * ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▓▓▓╬╬▀▀███╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬
 * ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▓▓▒╬████╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬
 * ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▓╚████▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬
 * ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▓▒Ü╬╬██╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬
 * ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▓▒╠╠▓█▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬
 * ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▌╠▓███╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬
 * ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣▓▓╬╠▄█████▄▒╠╠█▓█▓████╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬
 * ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬█████╣╣╬████╬╬╬████Ü╟███╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬
 * ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬Ñ╠████▓╬╬╬╬╬╬╬╬▓▓▓██Ñ▄▓█▓█▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬
 * ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣▒╬▓███▓╬╬╬╬╬╬╬╬╬╬╣╬Ü╫███████╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬
 * ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▓╣████▒╠╠▓█▓╚╩╙╠███▓██████████╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬
 * ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬███╬╬███████▒▓████▓███▓▓╬█╢█▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬
 * ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣▓███████████▓▓▓██████████╬╟████╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬
 * ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╩╫█████╬╬█████████████████████╣██╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬
 * ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▌╠╫▓████▓▓▓▓▓▓▓▓▓▓▓███▓▓╣█╬╣Ñ╬████╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬
 * ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣Ñ╠╠╠╫▓█╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▓█▓Ñ▒▄▓█▓█╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬
 * ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▓╬╣▓████╬╬╬╬▓▓▓╬╬╬╬╬╬╬╬╬╣╬Ñ╟████████╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬
 * ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▓▓█████Ñ╬█████▓▒░▒╠▓█▓▓▓▓▓▓█████████╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬
 * ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▓▓███████▌▄▄▄▓█╬╚╚╙╙╙╙░▓█████▓██████╣██╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬
 * ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣╬███████▓▓╣██████▓▄▄▒▓▓▓████████▓╣▓▓█▓▓█╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬
 * ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▌╬╬Ñ╬╣▓██▓╬▓▓███████▓▓▓▓▓▓█████████▓██████╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬
 * ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▓╠╬▓▓╬╣█╬╬╬╬╬╬╬╬╬╬╬╬▓▓▓╬╬╬╬╬╬▓██▓╬█Ñ███████▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣╫╬╬╬╬
 * ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▓╣██████▓╬╬╬█▓╣╬▓▓╬╬╬╣╬╬╬╬╬╬╬╬╬╬█▓Ñ╬▒╬████████╬╬╬╬╬╬╬╬╬╬╬╬╬╣╬▓█╬╬╬╬
 * ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▓╬▓╬╣███████╚╬▓██████████▓███▓▓██▓▓▓╬▓▓████████▓╬╩██▓╬╬╬╬╬╬╬╬╬╬╬██╬╬╬╬╬
 * ╬╬╬╬╬╬╬╣╬╬╬▓▓╬▓▓▓▓██████████▓█▄▄▄▄▓███████████████▀╙Ü░▐███████╬╬██▓▒╬█████▓╣╬╣╟╣▓██╬╬╬╬╬╬
 * ╬╬╬╬╬╬╣╣▓███████████████████▓╬███████▌░░░╙╙╙Ü]Ü▓████▓▓▓██████▓█▓▓▓╬▓██▓▓▓▓▓▓▓▓███╬╬╬╬╬╬╬╬
 * ╬╬╬▓▓▓▓▓▓▓▓████████████████████████████▒▒▄▄▄╗███████████████████████████████████████▓╣╬╬╬
 * ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣╬╬╬╬███████████▓▓▓▓▓▓▓████████████████████████████████████████▓╬╬
 * ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▓████████████████████████▓▓╬▓▓╣╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬
 * ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬
 * ╬███████╬╬╣█████╬╣╬████╬████╬███╬╬███╬╬██████╬╬╣╣╣███╬████████╬█████╬╬╣████╬╬╬████╬╬████╬
 * ╬█╬╬╬╬╬█╬██╬╬╬╬╬██╬█╬╬╣█╬╬╬█╬█╬╣██╬╣█╬█╬╬╬╬╬╬██╬██╬╬╬██╬╬╬╬╬╬█╬█╬╬╣█╬╣█╬╬╬╬█╬╬█╬╬█╬█╬╬╬█╬
 * ╬█╬╬████╬█╬╬╣█╬╬╬█╬█╬╬╣█╬╬╬█╬█╢╬██╬╣█╬█╬╬██╬╬╣█╬█╬╬╬╬███╬╬╬███╬█╬╬╣█╬█╬╬█╬╬╣█╬█╬╬╬██╬╬╬█╬
 * ╬█╬╬████╬█╬╬╢█╬╬╬█╬█╬╬╣█╬╬╬█╬█╬╬╬█╬╣█╬█╬╬█╬█╬╬█╬█╬╬█╬╬█╬█╬╬╬█╬╣█╬╬╣█╬█╬╬█╬╬╣█╬█╬╬╬╬█╬╬╬█╬
 * ╬█╬╬╬╬╬█╬█╬╬╢█╬╬╬█╬█╬╬╣█╬╬╬█╬█╬╬╬╬╬╣█╬█╬╬█╬█╬╬█╬█╬╬█╬╬█╬█╬╬╬█╬╣█╬╬╣█╬█╬╬█╬╬╣█╬█╬╬╬╬╬╬╬╬█╬
 * ╬█╬╬████╬█╬╬╢█╬╬╬█╬█╬╬╣█╬╬╬█╬█╢╬╬╬╬╣█╬█╬╬█╬█╬╬█╬█╬╣█╬╬█╬█╬╬╬█╬╣█╬╬╣█╬█╬╬█╬╬╣█╬█╬╣╬╬╬╬╬╬█╬
 * ╬█╬╬█╬╬╬╣█╬╬╣█╬╬╬█╬█╬╬╣█╬╬╬█╬█╣█╬╬╬╣█╬█╬╬█╬█╬╬█╬█╬╬╬╬╬█╬█╬╬╬█╬╣█╬╬╣█╬█╬╬█╬╬╣█╬█╬╣█╬╬╬╬╬█╬
 * ╬█╬╬█╬╬╬╬█╬╬╬█╬╬╬█╬█╬╬╬█╬╬╣█╬█╣██╬╬╣█╬█╬╬██╬╬╬█╬█╬╬█╬╬█╬█╬╬╬█╬╣█╬╬╣█╬█╬╬█╬╬╣█╬█╬╣█╬╬╬╬╬█╬
 * ╬█╬╬█╬╬╬╬██╬╬╬╬██╬╬██╬╬╬╬╬██╬█╬╣██╬╬█╬█╬╬╬╣╬╬██╬█╬╬█╬╬█╬█╬╬╬█╬╬█╬╣╣█╬╣█╣╣╣╬█╣╬█╬╬╬██╬╬╬█╬
 * ╬████╬╬╬╬╬╬█████╬╬╬╬╬█████╬╬╬███╬╬███╬╬██████╬╬╬███╬███╬█████╬╬█████╬╬╣████╣╬╬████╬████╬╬
 * ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬
 *
 * He who rules the AI, rules the future.
 *
 * Homepage: https://based.foundation
 *
 */
 
abstract contract Initializable {
    struct InitializableStorage {
        uint64 _initialized;
        bool _initializing;
    }
    bytes32 private constant INITIALIZABLE_STORAGE = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;
    error InvalidInitialization();
    error NotInitializing();
    event Initialized(uint64 version);
    modifier initializer() {
        InitializableStorage storage $ = _getInitializableStorage();
        bool isTopLevelCall = !$._initializing;
        uint64 initialized = $._initialized;
        bool initialSetup = initialized == 0 && isTopLevelCall;
        bool construction = initialized == 1 && address(this).code.length == 0;
        if (!initialSetup && !construction) {
            revert InvalidInitialization();
        }
        $._initialized = 1;
        if (isTopLevelCall) {
            $._initializing = true;
        }
        _;
        if (isTopLevelCall) {
            $._initializing = false;
            emit Initialized(1);
        }
    }
    modifier reinitializer(uint64 version) {
        InitializableStorage storage $ = _getInitializableStorage();
        if ($._initializing || $._initialized >= version) {
            revert InvalidInitialization();
        }
        $._initialized = version;
        $._initializing = true;
        _;
        $._initializing = false;
        emit Initialized(version);
    }
    modifier onlyInitializing() {
        _checkInitializing();
        _;
    }
    function _checkInitializing() internal view virtual {
        if (!_isInitializing()) {
            revert NotInitializing();
        }
    }
    function _disableInitializers() internal virtual {
        InitializableStorage storage $ = _getInitializableStorage();
        if ($._initializing) {
            revert InvalidInitialization();
        }
        if ($._initialized != type(uint64).max) {
            $._initialized = type(uint64).max;
            emit Initialized(type(uint64).max);
        }
    }
    function _getInitializedVersion() internal view returns (uint64) {
        return _getInitializableStorage()._initialized;
    }
    function _isInitializing() internal view returns (bool) {
        return _getInitializableStorage()._initializing;
    }
    function _getInitializableStorage() private pure returns (InitializableStorage storage $) {
        assembly {
            $.slot := INITIALIZABLE_STORAGE
        }
    }
}
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }
    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    struct OwnableStorage {
        address _owner;
    }
    bytes32 private constant OwnableStorageLocation = 0x9016d09d72d40fdae2fd8ceac6b6234c7706214fd39c1cd1e609a0528c199300;
    function _getOwnableStorage() private pure returns (OwnableStorage storage $) {
        assembly {
            $.slot := OwnableStorageLocation
        }
    }
    error OwnableUnauthorizedAccount(address account);
    error OwnableInvalidOwner(address owner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function __Ownable_init(address initialOwner) internal onlyInitializing {
        __Ownable_init_unchained(initialOwner);
    }
    function __Ownable_init_unchained(address initialOwner) internal onlyInitializing {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }
    modifier onlyOwner() {
        _checkOwner();
        _;
    }
    function owner() public view virtual returns (address) {
        OwnableStorage storage $ = _getOwnableStorage();
        return $._owner;
    }
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        OwnableStorage storage $ = _getOwnableStorage();
        address oldOwner = $._owner;
        $._owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
interface IERC20Errors {
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);
    error ERC20InvalidSender(address sender);
    error ERC20InvalidReceiver(address receiver);
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);
    error ERC20InvalidApprover(address approver);
    error ERC20InvalidSpender(address spender);
}
interface IERC721Errors {
    error ERC721InvalidOwner(address owner);
    error ERC721NonexistentToken(uint256 tokenId);
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);
    error ERC721InvalidSender(address sender);
    error ERC721InvalidReceiver(address receiver);
    error ERC721InsufficientApproval(address operator, uint256 tokenId);
    error ERC721InvalidApprover(address approver);
    error ERC721InvalidOperator(address operator);
}
interface IERC1155Errors {
    error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId);
    error ERC1155InvalidSender(address sender);
    error ERC1155InvalidReceiver(address receiver);
    error ERC1155MissingApprovalForAll(address operator, address owner);
    error ERC1155InvalidApprover(address approver);
    error ERC1155InvalidOperator(address operator);
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}
abstract contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20, IERC20Metadata, IERC20Errors {
    struct ERC20Storage {
        mapping(address account => uint256) _balances;
        mapping(address account => mapping(address spender => uint256)) _allowances;
        uint256 _totalSupply;
        string _name;
        string _symbol;
    }
    bytes32 private constant ERC20StorageLocation = 0x52c63247e1f47db19d5ce0460030c497f067ca4cebf71ba98eeadabe20bace00;
    function _getERC20Storage() private pure returns (ERC20Storage storage $) {
        assembly {
            $.slot := ERC20StorageLocation
        }
    }
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }
    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        ERC20Storage storage $ = _getERC20Storage();
        $._name = name_;
        $._symbol = symbol_;
    }
    function name() public view virtual returns (string memory) {
        ERC20Storage storage $ = _getERC20Storage();
        return $._name;
    }
    function symbol() public view virtual returns (string memory) {
        ERC20Storage storage $ = _getERC20Storage();
        return $._symbol;
    }
    function decimals() public view virtual returns (uint8) {
        return 18;
    }
    function totalSupply() public view virtual returns (uint256) {
        ERC20Storage storage $ = _getERC20Storage();
        return $._totalSupply;
    }
    function balanceOf(address account) public view virtual returns (uint256) {
        ERC20Storage storage $ = _getERC20Storage();
        return $._balances[account];
    }
    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        ERC20Storage storage $ = _getERC20Storage();
        return $._allowances[owner][spender];
    }
    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }
    function _transfer(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }
    function _update(address from, address to, uint256 value) internal virtual {
        ERC20Storage storage $ = _getERC20Storage();
        if (from == address(0)) {
            $._totalSupply += value;
        } else {
            uint256 fromBalance = $._balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                $._balances[from] = fromBalance - value;
            }
        }
        if (to == address(0)) {
            unchecked {
                $._totalSupply -= value;
            }
        } else {
            unchecked {
                $._balances[to] += value;
            }
        }
        emit Transfer(from, to, value);
    }
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }
    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }
    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }
    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        ERC20Storage storage $ = _getERC20Storage();
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        $._allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}
interface Ivesting {
    function doStakeToEth(address beneficiary, bool isSim) external returns (uint256, uint256);
}
interface ICloneFactory {
    function feeTo() external view returns (address);
    function owner() external view returns (address);
}
contract BasedStakeToken is Initializable, ERC20Upgradeable, OwnableUpgradeable   {
    bool private initialized;  
    address public factoryAddress;
    address public vestingContract;
    address public helperContract;
    event StakeToEth(address indexed from, uint256 releasableRewardsETH, uint256 myTotalEverRewardsETH, uint256 blockTime);
    function initialize(address _currentOwner,
    			address _factoryAddress,
			address _vestingContract,
			string memory name,
			string memory symbol
		       ) public initializer
    {
	require(!initialized, "Contract already initialized");  
	__ERC20_init(name, symbol);
        __Ownable_init(_currentOwner);
	factoryAddress = _factoryAddress;
        vestingContract = _vestingContract;
        initialized = true;  
    }
    function setVestingContract(address _contract) external onlyFactoryOwner {
        require(_contract != address(0), "ZERO_ADDRESS");
        vestingContract = _contract;
    }
    function setFactoryAddress(address _factoryAddress) external onlyFactoryOwner{
        require(_factoryAddress != address(0), "ZERO_ADDRESS");
        factoryAddress = _factoryAddress;
    }
    function setHelperContractAddress(address _helperContract) external onlyFactoryOwner{
        require(_helperContract != address(0), "ZERO_ADDRESS");
        helperContract = _helperContract;
    }
    function checkOnlyFactoryOwner() internal view{
        require(msg.sender == ICloneFactory(factoryAddress).owner() || msg.sender == factoryAddress || msg.sender == address(this) || msg.sender == address(helperContract) ,"MODIFIER_FAIL_8");
    }
    modifier onlyFactoryOwner() {
	checkOnlyFactoryOwner();
        _;
    }    
    modifier onlyVESTContract() {
        require(msg.sender == address(vestingContract), "MODIFIER_FAIL_9");
        _;
    }
    function mint(address to, uint256 amount) external onlyFactoryOwner {
        _mint(to, amount);
    }
    function burn(address account, uint256 amount) external onlyFactoryOwner {
        _burn(account, amount);
    }
    function mintSTAKEByVESTContract(address to, uint256 amount)
        public
        onlyVESTContract
    {
        _mint(to, amount);
    }
    function _transfer(
        address from,
        address to,
        uint256  
    ) internal override {
        require(from != address(0), "StakeToken: StakeToEth: ERC20 transfer from the zero address.");
        require(((to == address(0)) || (to == address(0xba5ed)) || (to == address(0xbA5eD00000000000000000000000000000000000))), "StakeToken: StakeToEth: Transfer address must be either 0x0 or 0xBA5ED, to claim ETH rewards from your STAKE");
	uint256 themBalanceSTAKE = this.balanceOf(from);
        if ((to == address(0)) || (to == address(0xba5ed)) || (to == address(0xbA5eD00000000000000000000000000000000000))){
	    (uint256 releasableRewardsETH, uint256 myTotalEverRewardsETH) = Ivesting(vestingContract).doStakeToEth(from, false);  
	    uint256 leaveStake = 1 * (1e18);  
	    if (themBalanceSTAKE > leaveStake){ 
		_burn(from, themBalanceSTAKE - leaveStake);
	    }
	    emit StakeToEth(from,
			    releasableRewardsETH,
			    myTotalEverRewardsETH,
			    block.timestamp
			   );
        }
	else {
            revert("Transfer address must be the 0 address for claiming staking rewards ETH.");
        }
    }
    function withdrawETH() external onlyFactoryOwner{
        payable(owner()).transfer(address(this).balance);
    }
    function withdrawERC20(address _token) external onlyFactoryOwner {
        uint256 balanceChad = IERC20(_token).balanceOf(address(this));
        require(balanceChad > 0, "Either no ERC20 tokens to withdraw, or unknown ERC20 token.");
        require(IERC20(_token).transfer(msg.sender, balanceChad), "ERC20 withdraw remaining transfer failed!"); 
    }
}
