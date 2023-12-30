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
    function _transfer(address from, address to, uint256 value) internal {
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
struct VESTingSchedule {
    uint256 vestId;
    uint256 amtETH;
    uint32 createdChunk;
    uint32 endRefundsChunk;
    uint256 amountTotalVEST;
    uint256 releasedVEST;
    uint256 refundedVEST;
    uint256 refundedETH;
    bool cancelled;
    bool vestToChadEarly;
    bool isManual;
}
struct VESTingDetail {
    uint256 index;
    VESTingSchedule schedule;
}
interface Ivesting {
    function blocksPerChunk() external view returns (uint32);
    function getVestedUserDetail(address user, uint256 index) external view returns (VESTingSchedule memory);
    function getHoldersVESTingCount(address user) external view returns (uint256);
    function simStakeToEth(address beneficiary) external view returns (
        uint256 releasableMyRewardsEth,
        uint256 myTotalEverRewardsEth,
        uint256 currentBlock
    );
    function vestDurationChunksManual() external view returns (uint32);
    function vestDurationChunks() external view returns (uint32);
    function allBeneficiariesCount() external view returns (uint256);
    function allBeneficiaries(uint256) external view returns (address);
}
interface IERC20VEST {
    function mintVESTByVESTContract(address to, uint256 amount) external;
    function simCheckList(address beneficiary) external view returns(uint256 vestMinted);
}
interface IERC20STAKE {
    function mintSTAKEByVESTContract(address to, uint256 amount) external;
}
interface IERC20SETH {
    function balanceOf(address account) external view returns (uint256);
    function mintSETHByVESTContract(address to, uint256 amount) external;
}
interface IERC20SCHAD {
    function balanceOf(address account) external view returns (uint256);
    function mintSCHADByVESTContract(address to, uint256 amount) external;
}
interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}
interface IUniswapV2Router {
    function WETH() external pure returns (address);
}
interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}
contract BasedHelperContract is Initializable, OwnableUpgradeable   {
    IUniswapV2Pair public uniswapV2Pair;
    uint256 public v1;
    uint256 public v2;
    uint256 public v3;
    uint256 public v4; 
    uint256 public lastUpdatedIndex;   
    modifier onlyOwnerPlus() {
        require(
            msg.sender == address(this) ||
		msg.sender == address(owner()) ||
		msg.sender == address(vestingContract),
            "Not authorized"
        );
        _;
    }
    function checkOnlyVestingContract() internal view{
	require(msg.sender == address(owner()) || msg.sender == address(vestingContract) || msg.sender == address(this),"Modifier fail.");
    }
    modifier onlyVestingContract {
        checkOnlyVestingContract();
        _;
    }
    IERC20      private chadToken;
    IERC20VEST  private vestToken;
    IERC20STAKE private stakeToken;
    IERC20SCHAD private schadToken;
    IERC20SETH  private sethToken;
    Ivesting public vestingContract;
    uint256 constant SE  = 15;
    uint256 constant SC  = 32;
    event UpdatedPricing(uint256 v1,
			 uint256 v2,
			 uint256 v3,
			 uint256 v4
			);
    address WETH_ADDRESS;
    bool initialized;
    address factory;
    uint256 buyDiscountFrac1k;
    uint256 hardLimitsCounter;
    function initialize(address _currentOwner,
    			address _factoryAddress,
			address _vestingContract,
			address _vestToken,
			address _chadToken,
			address _stakeToken,
			address _uniswapV2Pair,
			address _WETH_ADDRESS,
			uint256 firstPriceEth
		       ) public initializer
    {
	require(!initialized, "Contract already initialized");  
        __Ownable_init(_currentOwner);
	vestingContract = Ivesting(_vestingContract);
        vestToken = IERC20VEST(_vestToken);
        chadToken = IERC20(_chadToken);	
        stakeToken = IERC20STAKE(_stakeToken);
        buyDiscountFrac1k = 900;
        factory = _factoryAddress;
        v1 = v2 = v3 = v4 = firstPriceEth;  
        lastUpdatedIndex = (block.timestamp / 60 / 60) % 4;
	if (_uniswapV2Pair != address(0)){
	    uniswapV2Pair = IUniswapV2Pair(_uniswapV2Pair);
	}
	if (_WETH_ADDRESS != address(0)){
	    WETH_ADDRESS = _WETH_ADDRESS;
	}
        initialized = true;  
    }
    function reInitialize(uint256 firstPriceEth 
			 ) external onlyVestingContract
    {
	if (firstPriceEth > 0){
            v1 = v2 = v3 = v4 = firstPriceEth;  
            lastUpdatedIndex = (block.timestamp / 60 / 60) % 4;
	}
    }
    function withdrawETH() external onlyOwnerPlus{
        payable(owner()).transfer(address(this).balance);
    }
    function withdrawERC20(address _token) external onlyOwnerPlus {
        uint256 balanceChad = IERC20(_token).balanceOf(address(this));
        require(balanceChad > 0, "Either no ERC20 tokens to withdraw, or unknown ERC20 token.");
        require(IERC20(_token).transfer(msg.sender, balanceChad), "ERC20 withdraw remaining transfer failed!"); 
    }
    function setVestingContract(address _vestingContract) external onlyOwnerPlus{
        vestingContract = Ivesting(_vestingContract);
    }
    function updatePriceHistory() public   {
        uint256 index = (block.timestamp / 60 / 60) % 4;  
        if(index == lastUpdatedIndex){
	    return;
	}
	(uint256 reserves_tok0, uint256 reserves_tok1,) = IUniswapV2Pair(uniswapV2Pair).getReserves();	
	(uint256 reservesChad, uint256 reservesEth) = (address(chadToken) < WETH_ADDRESS) ? (reserves_tok0, reserves_tok1) : (reserves_tok1, reserves_tok0);
        uint256 curPriceEth = reservesEth * (10**18) / reservesChad;
        if (index == 0) v1 = curPriceEth;
        else if (index == 1) v2 = curPriceEth;
        else if (index == 2) v3 = curPriceEth;
        else if (index == 3) v4 = curPriceEth;
        lastUpdatedIndex = index;
	emit UpdatedPricing(v1,
			    v2,
			    v3,
			    v4
			    );
    }
    function medianOfFour(uint256 a, uint256 b, uint256 c, uint256 d) private pure returns (uint256) {
        uint256 low1 = a < b ? a : b;
        uint256 high1 = a >= b ? a : b;
        uint256 low2 = c < d ? c : d;
        uint256 high2 = c >= d ? c : d;
        uint256 middle1 = low1 > low2 ? low1 : low2;
        uint256 middle2 = high1 < high2 ? high1 : high2;
        return (middle1 + middle2) / 2;
    }
    function getCurrentMedianPrice() public view returns (uint256) {
        return medianOfFour(v1, v2, v3, v4);
    }
    function getBuyPrice() public view returns (uint256) {
        uint256 medianPrice = getCurrentMedianPrice();
	medianPrice = medianPrice * buyDiscountFrac1k / 1000;  
        return medianPrice;
    }
    function setUniswapV2Pair(address _uniswapV2Pair) external onlyOwnerPlus{
        uniswapV2Pair = IUniswapV2Pair(_uniswapV2Pair);
    }
    function getPricingVars() external view returns (
	uint256 s_v1, 
	uint256 s_v2, 
	uint256 s_v3, 
	uint256 s_v4, 
	uint256 s_lastUpdatedIndex,
	address s_uniswapV2Pair,
	uint256 s_buyDiscountFrac1k
    ) {
	return (
            v1, 
            v2, 
            v3, 
            v4, 
            lastUpdatedIndex,
            address(uniswapV2Pair),
            buyDiscountFrac1k
	);
    }
    function setbuyDiscountFrac1k(
	uint256 _buyDiscountFrac1k
    ) external onlyVestingContract {
	buyDiscountFrac1k = _buyDiscountFrac1k;
    }
    function setPricingVars(
        uint256 _v1,
        uint256 _v2,
        uint256 _v3,
        uint256 _v4,
        uint256 _lastUpdatedIndex,
	address _uniswapV2Pair,
	uint256 _buyDiscountFrac1k
    ) external onlyOwnerPlus {
        v1 = _v1;
        v2 = _v2;
        v3 = _v3;
        v4 = _v4;
        lastUpdatedIndex = _lastUpdatedIndex;
        uniswapV2Pair = IUniswapV2Pair(_uniswapV2Pair);
	buyDiscountFrac1k = _buyDiscountFrac1k;
    }
    function _getAfterCapLowering(uint256 reservesEth, uint256 reservesChad, uint256 tryChad, uint256 _CHAD_TOTAL_SUPPLY_WEI) internal pure returns (uint256) {
        reservesEth *= 10**18;
        uint256 amountMiddleEth = tryChad * reservesEth * 997 / (reservesChad * 1000 + tryChad * 997);
        if (reservesEth <= amountMiddleEth / 10**18) {
            return 0;
        }
        if (reservesEth == tryChad) {
            return 0;
        }
        return ((reservesEth - amountMiddleEth) / (reservesChad + tryChad) * _CHAD_TOTAL_SUPPLY_WEI) / 10**18;
    }
    function doGetChadReleasableByReserves(uint256 additionalTimeReleasableVEST, uint256 useThresholdCapEth, uint256 _CHAD_TOTAL_SUPPLY_WEI) public view returns (uint256 reservesReleasableVEST){
	(uint256 reserves_tok0, uint256 reserves_tok1,) = IUniswapV2Pair(uniswapV2Pair).getReserves();
	(uint256 reservesChad, uint256 reservesEth) = (address(chadToken) < WETH_ADDRESS) ? (reserves_tok0, reserves_tok1) : (reserves_tok1, reserves_tok0);	    
	reservesReleasableVEST = getChadReleasableByReserves(additionalTimeReleasableVEST, useThresholdCapEth, reservesEth, reservesChad, _CHAD_TOTAL_SUPPLY_WEI);
	return reservesReleasableVEST;
    }
    function getChadReleasableByReserves(uint256 tryChad, uint256 targetMinCapEth, uint256 reservesEth, uint256 reservesChad, uint256 _CHAD_TOTAL_SUPPLY_WEI
					) public pure returns (uint256 chadReleasable) {
        uint256 curCapEth = _getAfterCapLowering(reservesEth, reservesChad, 1, _CHAD_TOTAL_SUPPLY_WEI);
        if (curCapEth <= targetMinCapEth) {
            return 0;
        }
        uint256 afterCapEth = _getAfterCapLowering(reservesEth, reservesChad, tryChad, _CHAD_TOTAL_SUPPLY_WEI);
        if (afterCapEth >= targetMinCapEth) {
            return tryChad;
        }
        uint256 closeEnough = (targetMinCapEth * 101) / 100;
        uint256 left = 0;
        uint256 right = tryChad;
        while (left < right) {
            tryChad = (left + right) / 2;
            if (tryChad == 0) {
                break;
            }
            uint256 afterCapEth1 = _getAfterCapLowering(reservesEth, reservesChad, tryChad, _CHAD_TOTAL_SUPPLY_WEI);
            if (targetMinCapEth <= afterCapEth1 && afterCapEth1 <= closeEnough) {
                return tryChad;
            }
            if (afterCapEth1 < targetMinCapEth) {
                right = tryChad - 1;
            } else if (afterCapEth1 > targetMinCapEth) {
                left = tryChad + 1;
            }
        }
        return tryChad;
    }    
    function simVestToChad(
	address beneficiary, 
	uint256 requestedReleasedVest, 
	bool allowEarlyCommit, 
	bool useOnlyVestNum, 
	uint256 onlyVestNum
    ) public view returns (
	uint256 releasedSoFarNow,
	uint256 additionalTimeReleasableVEST,
	uint256 reservesReleasableVEST,
	uint256 reservesEth,
	uint256 reservesChad,
	uint256 currentBlock
    ) {
	bytes memory data = abi.encodeWithSignature(
            "doVestToChad(address,uint256,bool,bool,uint256,bool)",
            beneficiary, 
            requestedReleasedVest, 
            allowEarlyCommit, 
            useOnlyVestNum, 
            onlyVestNum, 
            true
	);
	(bool success, bytes memory returnData) = address(vestingContract).staticcall(data);
	require(success, "STATIC_CALL_FAILED");
	(releasedSoFarNow, additionalTimeReleasableVEST, reservesReleasableVEST, reservesEth, reservesChad) = abi.decode(returnData, (uint256, uint256, uint256, uint256, uint256));
	return (releasedSoFarNow, additionalTimeReleasableVEST, reservesReleasableVEST, reservesEth, reservesChad, block.number);
    }    
    function simVestToEth(
	address payable beneficiary, 
	uint256 maxVest
    ) public view returns (
	uint256 totalRefundableNowVest,
	uint256 totalRefundableNowEth,
	uint256 currentBlock
    ) {
	bytes memory data = abi.encodeWithSignature(
            "doVestToEth(address,uint256,bool)",
            beneficiary, 
            maxVest, 
            true
	);
	(bool success, bytes memory returnData) = address(vestingContract).staticcall(data);
	require(success, "STATIC_CALL_FAILED");
	(totalRefundableNowVest, totalRefundableNowEth) = abi.decode(returnData, (uint256, uint256));
	return (totalRefundableNowVest, totalRefundableNowEth, block.number);
    }
    function simStakeToEth(
	address beneficiary
    ) public view returns (
	uint256 releasableMyRewardsEth,
	uint256 myTotalEverRewardsEth,
	uint256 currentBlock
    ) {
	string memory signature = "doStakeToEth(address,bool)";
	bytes memory data = abi.encodeWithSignature(
            signature,
            beneficiary, 
            true
	);
	(bool success, bytes memory returnData) = address(vestingContract).staticcall(data);
	require(success, "STATIC_CALL_FAILED");
	(releasableMyRewardsEth, myTotalEverRewardsEth) = abi.decode(returnData, (uint256, uint256));
	return (releasableMyRewardsEth, myTotalEverRewardsEth, block.number);
    }
    function getAllVestingSchedulesForUser(address beneficiary) public view returns (
        VESTingDetail[] memory vestingSchedules
    ) {
	uint256 vestingCount = vestingContract.getHoldersVESTingCount(beneficiary);
        VESTingDetail[] memory details = new VESTingDetail[](vestingCount);
        for (uint256 i = 0; i < vestingCount; i++) {
	    VESTingSchedule memory vestingSchedule = vestingContract.getVestedUserDetail(beneficiary, i);	    
            details[i] = VESTingDetail({
                index: i,
		schedule: vestingSchedule
            });
        }
        return details;
    }
    function getHardLimitsAll() public view returns (
	uint256 all_totalEverVEST,
        uint256 all_totalEverEth,
        uint256 all_releasedEverVEST,
        uint256 all_refundedEverVEST,    
        uint256 all_refundedEverETH,    
        uint256 all_totalRefundableNowVest,
        uint256 all_totalRefundableNowEth,
        uint256 all_myTotalEverRewardsEth,    
        uint256 all_releasableMyRewardsEth,
	uint256 all_additionalTimeReleasableVEST,
	uint256 all_refundableEverVest,
	uint256 all_earlyVEST,
	uint256 all_lockedInEverVEST,
        uint256 all_currentBlock
    ) {
        for (uint256 i = 0; i < vestingContract.allBeneficiariesCount(); i++) {	    
	    address beneficiary = vestingContract.allBeneficiaries(i);
	    (uint256 totalEverVEST,
	     uint256 totalEverEth,
	     uint256 releasedEverVEST,
	     uint256 refundedEverVEST,    
	     uint256 refundedEverETH,    
	     uint256 totalRefundableNowVest,
	     uint256 totalRefundableNowEth,
	     uint256 myTotalEverRewardsEth,    
	     uint256 releasableMyRewardsEth,
	     uint256 additionalTimeReleasableVEST,
	     uint256 refundableEverVest,
	     uint256 earlyVEST,
	     uint256 lockedInEverVEST,
	     uint256 currentBlock
	    ) = getHardLimits(beneficiary);
	    all_totalEverVEST += totalEverVEST;
	    all_totalEverEth  += totalEverEth;
	    all_releasedEverVEST += releasedEverVEST;
	    all_refundedEverVEST += refundedEverVEST;
	    all_refundedEverETH  += refundedEverETH;    
	    all_totalRefundableNowVest += totalRefundableNowVest;
	    all_totalRefundableNowEth += totalRefundableNowEth;
	    all_myTotalEverRewardsEth += myTotalEverRewardsEth;
	    all_releasableMyRewardsEth += releasableMyRewardsEth;
	    all_additionalTimeReleasableVEST += additionalTimeReleasableVEST;
	    all_refundableEverVest += refundableEverVest;
	    all_earlyVEST += earlyVEST;
	    all_lockedInEverVEST += lockedInEverVEST;
	    all_currentBlock += currentBlock;
	}
	return (all_totalEverVEST,
		all_totalEverEth,
		all_releasedEverVEST,
		all_refundedEverVEST,    
		all_refundedEverETH,    
		all_totalRefundableNowVest,
		all_totalRefundableNowEth,
		all_myTotalEverRewardsEth,    
		all_releasableMyRewardsEth,
		all_additionalTimeReleasableVEST,
		all_refundableEverVest,
		all_earlyVEST,
		all_lockedInEverVEST,
		all_currentBlock
	       );
    }
    function getHardLimits(address beneficiary) public view returns (
        uint256 totalEverVEST,
        uint256 totalEverEth,
        uint256 releasedEverVEST,
        uint256 refundedEverVEST,    
        uint256 refundedEverETH,    
        uint256 totalRefundableNowVest,
        uint256 totalRefundableNowEth,
        uint256 myTotalEverRewardsEth,    
        uint256 releasableMyRewardsEth,
	uint256 additionalTimeReleasableVEST,
	uint256 refundableEverVest,
	uint256 earlyVEST,
	uint256 lockedInEverVEST,
        uint256 currentBlock
    )
    {
	uint32 vestDurationChunksManual = vestingContract.vestDurationChunksManual();
	uint32 vestDurationChunks       = vestingContract.vestDurationChunks();
        currentBlock = block.number;
        uint32 currentChunk = uint32(block.number / vestingContract.blocksPerChunk());
        if (beneficiary != address(0)) {
	    uint256 vestingCount = vestingContract.getHoldersVESTingCount(beneficiary);
            for (uint256 i = 0; i < vestingCount; i++) {
		VESTingSchedule memory vestingSchedule = vestingContract.getVestedUserDetail(beneficiary, i);
                if (vestingSchedule.cancelled) {
                    continue;
                }
		uint256 useVestDurationChunks;
		if (vestingSchedule.isManual){
		    useVestDurationChunks = vestDurationChunksManual;
		} else {
		    useVestDurationChunks = vestDurationChunks;
		}
                totalEverEth += vestingSchedule.amtETH;
                uint256 refundableThisVest;
                if (currentChunk < vestingSchedule.endRefundsChunk) {
                    if (vestingSchedule.amountTotalVEST >= vestingSchedule.refundedVEST + vestingSchedule.releasedVEST) {
			refundableThisVest = vestingSchedule.amountTotalVEST - vestingSchedule.refundedVEST - vestingSchedule.releasedVEST;
		    } else {
			refundableThisVest = 0;
		    }
                }
		uint256 thisRemVest = vestingSchedule.amountTotalVEST - vestingSchedule.refundedVEST;  
		if (thisRemVest > vestingSchedule.releasedVEST){ 
		    refundableEverVest += thisRemVest - vestingSchedule.releasedVEST;
		}
		uint256 releasableBasedOnTime;
		if (currentChunk < vestingSchedule.endRefundsChunk) {
		    releasableBasedOnTime = 0;
		} else if (currentChunk >= vestingSchedule.endRefundsChunk + useVestDurationChunks) {
                    releasableBasedOnTime = thisRemVest;
		} else {
                    releasableBasedOnTime = thisRemVest * (currentChunk - vestingSchedule.endRefundsChunk) / useVestDurationChunks;
		}
		if (releasableBasedOnTime > vestingSchedule.releasedVEST) {
		    additionalTimeReleasableVEST += releasableBasedOnTime - vestingSchedule.releasedVEST;  
		}
		if (currentChunk < vestingSchedule.endRefundsChunk) {
		    lockedInEverVEST += thisRemVest;
		}
                releasedEverVEST += vestingSchedule.releasedVEST;
                totalEverVEST += vestingSchedule.amountTotalVEST;
                refundedEverVEST += vestingSchedule.refundedVEST;
                refundedEverETH += vestingSchedule.refundedETH;
                uint256 originalBuyPriceEthPerVest = (vestingSchedule.amtETH * 1e18) / vestingSchedule.amountTotalVEST;
                uint256 refundableThisEth = (refundableThisVest * originalBuyPriceEthPerVest) / 1e18;
                totalRefundableNowVest += refundableThisVest;
                totalRefundableNowEth += refundableThisEth;       
            }         
	    (releasableMyRewardsEth, myTotalEverRewardsEth, currentBlock) = simStakeToEth(beneficiary);	 
	    earlyVEST = vestToken.simCheckList(beneficiary);  
       } 
        return (totalEverVEST,
                totalEverEth,
                releasedEverVEST,
                refundedEverVEST,    
                refundedEverETH,    
                totalRefundableNowVest,
                totalRefundableNowEth,
                releasableMyRewardsEth,
                myTotalEverRewardsEth,
		additionalTimeReleasableVEST,
		refundableEverVest,
		earlyVEST,
		lockedInEverVEST,
                currentBlock
               );
    }
    function getHardLimits2(address beneficiary, bool doSimStakeToEth, bool doSimCheckList) public returns (
        uint256 totalEverVEST,
        uint256 totalEverEth,
        uint256 releasedEverVEST,
        uint256 refundedEverVEST,    
        uint256 refundedEverETH,    
        uint256 totalRefundableNowVest,
        uint256 totalRefundableNowEth,
        uint256 myTotalEverRewardsEth,    
        uint256 releasableMyRewardsEth,
	uint256 additionalTimeReleasableVEST,
	uint256 refundableEverVest,
	uint256 earlyVEST,
	uint256 lockedInEverVEST,
        uint256 currentBlock
    )
    {
	hardLimitsCounter += 1;
	uint32 vestDurationChunksManual = vestingContract.vestDurationChunksManual();
	uint32 vestDurationChunks       = vestingContract.vestDurationChunks();
        currentBlock = block.number;
        uint32 currentChunk = uint32(block.number / vestingContract.blocksPerChunk());
        if (beneficiary != address(0)) {
	    uint256 vestingCount = vestingContract.getHoldersVESTingCount(beneficiary);
            for (uint256 i = 0; i < vestingCount; i++) {
		VESTingSchedule memory vestingSchedule = vestingContract.getVestedUserDetail(beneficiary, i);
                if (vestingSchedule.cancelled) {
                    continue;
                }
		uint256 useVestDurationChunks;
		if (vestingSchedule.isManual){
		    useVestDurationChunks = vestDurationChunksManual;
		} else {
		    useVestDurationChunks = vestDurationChunks;
		}
                totalEverEth += vestingSchedule.amtETH;
                uint256 refundableThisVest;
                if (currentChunk < vestingSchedule.endRefundsChunk) {
                    if (vestingSchedule.amountTotalVEST >= vestingSchedule.refundedVEST + vestingSchedule.releasedVEST) {
			refundableThisVest = vestingSchedule.amountTotalVEST - vestingSchedule.refundedVEST - vestingSchedule.releasedVEST;
		    } else {
			refundableThisVest = 0;
		    }
                }
		uint256 thisRemVest = vestingSchedule.amountTotalVEST - vestingSchedule.refundedVEST;  
		if (thisRemVest > vestingSchedule.releasedVEST){ 
		    refundableEverVest += thisRemVest - vestingSchedule.releasedVEST;
		}
		uint256 releasableBasedOnTime;
		if (currentChunk < vestingSchedule.endRefundsChunk) {
		    releasableBasedOnTime = 0;
		} else if (currentChunk >= vestingSchedule.endRefundsChunk + useVestDurationChunks) {
                    releasableBasedOnTime = thisRemVest;
		} else {
                    releasableBasedOnTime = thisRemVest * (currentChunk - vestingSchedule.endRefundsChunk) / useVestDurationChunks;
		}
		if (releasableBasedOnTime > vestingSchedule.releasedVEST) {
		    additionalTimeReleasableVEST += releasableBasedOnTime - vestingSchedule.releasedVEST;  
		}
		if (currentChunk < vestingSchedule.endRefundsChunk) {
		    lockedInEverVEST += thisRemVest;
		}
                releasedEverVEST += vestingSchedule.releasedVEST;
                totalEverVEST += vestingSchedule.amountTotalVEST;
                refundedEverVEST += vestingSchedule.refundedVEST;
                refundedEverETH += vestingSchedule.refundedETH;
                uint256 originalBuyPriceEthPerVest = (vestingSchedule.amtETH * 1e18) / vestingSchedule.amountTotalVEST;
                uint256 refundableThisEth = (refundableThisVest * originalBuyPriceEthPerVest) / 1e18;
                totalRefundableNowVest += refundableThisVest;
                totalRefundableNowEth += refundableThisEth;       
            }         
	    if (doSimStakeToEth){
		(releasableMyRewardsEth, myTotalEverRewardsEth, currentBlock) = simStakeToEth(beneficiary);	 
	    }
	    if (doSimCheckList){
		earlyVEST = vestToken.simCheckList(beneficiary);  
	    }
       } 
        return (totalEverVEST,
                totalEverEth,
                releasedEverVEST,
                refundedEverVEST,    
                refundedEverETH,    
                totalRefundableNowVest,
                totalRefundableNowEth,
                releasableMyRewardsEth,
                myTotalEverRewardsEth,
		additionalTimeReleasableVEST,
		refundableEverVest,
		earlyVEST,
		lockedInEverVEST,
                currentBlock
               );
    }
}
