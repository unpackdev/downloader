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
interface IERC20VEST {
    function mintVESTByVESTContract(address to, uint256 amount) external;
}
interface IERC20STAKE {
    function mintSTAKEByVESTContract(address to, uint256 amount) external;
}
interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}
interface IUpgradedVesting {
    function doEthToVest(address useSender) payable external;  
}
interface IHelperContract {
    function updatePriceHistory() external;
    function getBuyPrice() external view returns (uint256);
    function doGetChadReleasableByReserves(uint256 additionalTimeReleasableVEST, uint256 useThresholdCapEth, uint256 CHAD_TOTAL_SUPPLY_WEI) external returns (uint256 reservesReleasableVEST);
    function setbuyDiscountFrac1k(uint256 _buyDiscountFrac1k) external;
    function reInitialize(uint256 firstPriceEth
			 ) external;
}
interface ICloneFactory {
    function feeTo() external view returns (address);
    function owner() external view returns (address);
}
contract BasedMarket is Initializable, OwnableUpgradeable      {
    bool private initialized;  
    bool internal locked;
    modifier nonReentrantIsSim(bool isSim) {
	if (!isSim){
	    require(!locked,"REENTRANT_ISSIM");
	    locked = true;
	}
	_;
	if (!isSim){
	    locked = false;
	}
    }
    modifier nonReentrant() {
	require(!locked,'REENTRANT');
	locked = true;
	_;
	locked = false;
    }
    bool internal lockedInner;
    modifier nonReentrantInner() {
	require(!lockedInner,"REENTRANT_INNER");
	lockedInner = true;
	_;
	lockedInner = false;
    }
    address     private factoryAddress;
    IERC20      private chadToken;
    IERC20VEST  private vestToken;
    IERC20STAKE private stakeToken;
    address private helperContract;  
    address private uniswapV2Pair;
    bool private useAutoPricing;
    bool private salesLive;
    address private replacementAddress;
    uint32 private curLastMaturityChunk;
    uint32 public individualRefundChunks;
    uint32 public  vestDurationChunks;
    uint32 public  vestDurationChunksManual;
    address[] public allBeneficiaries;
    uint256 public allBeneficiariesCount;
    uint256 private CUR_TOTAL_CHAD_PURCHASED;  
    uint256 private TOTAL_CHAD_FOR_SALE_CAP;  
    uint256 private CHAD_TOTAL_SUPPLY_WEI;
    uint256 private POST_CAP_THRESHOLD_ETH; 
    uint256 private buyPriceEthPerVest;    
    uint32  public  blocksPerChunk;
    uint32  private maxChunksPerStaking;
    uint256 private fracStakingRewards1k;
    bool private allowEarlyChadLockin;
    bool private liquiditySensitive;
    uint256 unlockThreshDiscountFrac1k;
    struct DECStruct {
        uint64 a_inChadExternalSellers;  
        uint64 a_inChadDisembursedToSellers;
        uint64 a_outChadUndecided;
        uint64 a_outEthUndecided;
        uint64 a_inEthDisembursedStakersRefund;
        uint64 a_outChadExternalSellers;
	uint64 a_outChadRecycle;
        uint64 a_inChadUndecided;
        uint64 a_outEthExternalBuyers;
        uint64 a_inEthUndecided;
        uint64 a_inEthSellersEarly;
        uint64 a_inEthStakeHoldersEarly;
        uint64 a_outChadVestHolders;
        uint64 a_inChadDisembursedHolders;
        uint64 a_inChadVestHolders;
	uint64 a_inChadVestHoldersEarly;
        uint64 a_inEthSellers;
        uint64 a_inEthStakeHolders;
        uint64 a_outEthStakeHolders;
        uint64 a_inEthDisembursedStakersRewards;
    }
    DECStruct public DEC;
    bool doDoubleAccountingChecks;
    uint32 lastFinalizedRewardsChunkUpdated;
    bool allowEarlyStakingPayouts;
    uint256 private vestIdSeq;
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
    mapping(address => mapping(uint256 => VESTingSchedule)) private vestedUserDetail;
    mapping(address => uint256) private holdersVESTingCount;
    struct AddressIndexPair {
        address addr;
        uint idx;
    }
    AddressIndexPair[] private vestedUserDetailByAddressIndex;
    mapping(uint32 => uint256) private stake_block_tot_held_eth_early;    
    mapping(uint32 => uint256) private stake_block_tot_held_chad_early;    
    mapping(uint32 => uint256) private stake_block_tot_held_eth;    
    mapping(uint32 => mapping(address => uint256)) private stake_block_holder_nonheld_eth;    
    mapping(uint32 => uint256) private stake_block_tot_nonheld_eth;
    mapping(uint32 => mapping(address => uint256)) private stake_block_who_reward_already_paid_eth;  
    mapping(uint32 => uint256) private stake_block_tot_held_chad;
    mapping(uint32 => uint256) private stake_block_tot_refunded_eth;
    event EthToVest(address user,
		    uint256 vestId,
		    uint256 spentEth,
		    uint256 numberOfVEST,
		    uint32 _startingChunk,
		    uint32 _endRefundsChunk,
		    bool _isManual
                   );
    event VestToChad(address user,
		     uint256 releasedSoFarNow,
		     uint256 additionalTimeReleasableVEST,
		     uint256 reservesReleasableVEST,
		     uint256 reservesEth,
		     uint256 reservesChad,
		     uint256 totalRefundableVest
		    );
    event VestToEth(address user,
		    uint256 totalRefundableNowVest,
		    uint256 totalRefundableNowEth
		   );
    event VestToChadEarly(address beneficiary,
			  uint256 totEarlyLockedChad,
			  uint256 totEarlyLockedEth
			 );
    event StakeToEth(address user,
		    uint256 releasableMyRewardsEth,
		    uint256 myTotalEverRewardsEth
		    );
    event StakeToEthEarly(address beneficiary,
			  uint32 xChunk,
			  uint256 thisChunkMyRewardsEth,
			  uint256 everyoneHoldersThisChunk,
			  uint256 everyonesStakeThisChunk,
			  uint256 earlyHoldersThisChunk,
			  uint256 myAlreadyPaidThisChunk
			 );
    event SellerWithdrewChad(uint256 amountChadOut,
			     uint256 new_TOTAL_CHAD_FOR_SALE_CAP,
			     uint64 a_inChadUndecided,
			     uint64 a_outChadRecycle,
			     uint64 a_inChadDisembursedHolders
			    );
    event SellerDepositedChad(uint256 amountChad,
			      uint256 new_TOTAL_CHAD_FOR_SALE_CAP,
			      uint256 CUR_TOTAL_CHAD_PURCHASED,			      
			      uint256 TOTAL_CHAD_FOR_SALE_CAP,
			      address sellerAddress,
			      uint256 initialPrice,
			      bool _useAutoPricing
			       );
    event SellerPaidEthEarly(uint256 totalToPaySellerLate,
			     address sellerAddress
			    );
    event SellerPaidEthLate(uint256 totalToPaySellerLate,
			    address sellerAddress
			   );
    uint256 constant SE  = 15;
    uint256 constant SC  = 32;
    bool private isInternalCall;  
    bool private rewardEarlyChunks;
    address private WETH_ADDRESS;
    address[] private oldMarketAddresses;
    function finishInitialize(address _vestToken,
			      address _stakeToken,
			      address _uniswapV2Pair,
			      address _WETH_ADDRESS,
			      address _helperContract,
			      uint256 firstPriceEth
			     ) public onlyFactoryOwner
    {
	require(msg.sender == factoryAddress, 'ONLY_CLONE_FACTORY');
        vestToken = IERC20VEST(_vestToken);
        stakeToken = IERC20STAKE(_stakeToken);
        uniswapV2Pair = address(_uniswapV2Pair); 
        helperContract = _helperContract;
	WETH_ADDRESS = _WETH_ADDRESS;
	buyPriceEthPerVest = firstPriceEth;
	if (firstPriceEth > 0){
            liquiditySensitive = true;
	}
	salesLive = false;  
    }
    function initialize(address _creatorOwner,
    			address _factoryAddress,
			address _chadToken,
			uint32 _blocksPerChunk,                          
			uint32 _individualRefundChunks,                  
			uint32 _maxChunksPerStaking,                     
			uint32 _vestDurationChunks,                     
			uint32 _vestDurationChunksManual,
			uint256 _fracStakingRewards1k,           
			uint256 _unlockThreshDiscountFrac1k,                
			bool _useAutoPricing,             
			uint256 _CHAD_TOTAL_SUPPLY_WEI,  
			uint256 _POST_CAP_THRESHOLD_ETH,                       
			bool _allowEarlyChadLockin,                    
			bool _rewardEarlyChunks,
			bool _allowEarlyStakingPayouts,			
			bool _doDoubleAccountingChecks               
		       ) public initializer
    {
	require(!initialized, "Contract already initialized");  
	__Ownable_init(_creatorOwner);
	initialized = true;  
	require(_factoryAddress != address(0), "ZERO_FACTORY_ADDRESS");
	factoryAddress = _factoryAddress;
	vestIdSeq = 1;
        chadToken = IERC20(_chadToken);
        blocksPerChunk         = _blocksPerChunk;                    
        individualRefundChunks = _individualRefundChunks;                    
        maxChunksPerStaking    = _maxChunksPerStaking;                    
        vestDurationChunks     = _vestDurationChunks;                    
	vestDurationChunksManual  = _vestDurationChunksManual;
        fracStakingRewards1k =  _fracStakingRewards1k;           
	unlockThreshDiscountFrac1k = _unlockThreshDiscountFrac1k;                
	useAutoPricing = _useAutoPricing;             
        CHAD_TOTAL_SUPPLY_WEI = _CHAD_TOTAL_SUPPLY_WEI;  
        POST_CAP_THRESHOLD_ETH = _POST_CAP_THRESHOLD_ETH;                       
        allowEarlyChadLockin = _allowEarlyChadLockin;                    
        rewardEarlyChunks = _rewardEarlyChunks;
        uint32 currentChunk = uint32(block.number / blocksPerChunk);
        lastFinalizedRewardsChunkUpdated = currentChunk - 1;
	curLastMaturityChunk = currentChunk;
        allowEarlyStakingPayouts = _allowEarlyStakingPayouts;
        doDoubleAccountingChecks = _doDoubleAccountingChecks;               
    }
    function checkOnlyVESTTokenOrThisOrHelper() internal view {	
	require(isInternalCall || msg.sender == address(vestToken) || msg.sender == factoryAddress || msg.sender == address(this)  || msg.sender == ICloneFactory(factoryAddress).owner() || msg.sender == address(helperContract),"MODIFIER_FAIL_1");   
    }
    modifier onlyVESTTokenOrThisOrHelper {
    	checkOnlyVESTTokenOrThisOrHelper();
        _;
    }
    function checkOnlySTAKETokenOrThisOrHelper() internal view {
	require(msg.sender == factoryAddress || msg.sender == address(stakeToken) || msg.sender == address(this) || msg.sender == address(helperContract) || msg.sender == ICloneFactory(factoryAddress).owner(),"MODIFIER_FAIL_4");
    }
    modifier onlySTAKETokenOrThisOrHelper {
        checkOnlySTAKETokenOrThisOrHelper(); 
        _;
    }
    function checkOnlyFactoryOwner() internal view{
        require(msg.sender == factoryAddress || msg.sender == address(this) || msg.sender == address(helperContract) || msg.sender == ICloneFactory(factoryAddress).owner() ,"MODIFIER_FAIL_6");
    }
    modifier onlyFactoryOwner() {
	checkOnlyFactoryOwner();
        _;
    }
    function setVestedUserDetail(address user, uint256 index, VESTingSchedule memory schedule) external onlyFactoryOwner {
        vestedUserDetail[user][index] = schedule;
    }
    function setHoldersVESTingCount(address user, uint256 count) external onlyFactoryOwner {
        holdersVESTingCount[user] = count;
    }
    function getVestedUserDetail(address user, uint256 index) external view returns (VESTingSchedule memory) {
        return vestedUserDetail[user][index];
    }
    function getHoldersVESTingCount(address user) external view returns (uint256) {
        return holdersVESTingCount[user];
    }
    function xSE(uint256 x) internal pure returns (uint64) {
        return uint64(x >> 15);
    }
    function xSC(uint256 x) internal pure returns (uint64) {
        return uint64(x >> 32);
    }
    function uSE(uint64 x) internal pure returns (uint256) {
        return uint256(x) << 15;
    }
    function uSC(uint64 x) internal pure returns (uint256) {
        return uint256(x) << 32;
    }
    function uSExSE(uint256 x) internal pure returns (uint256) {
        return (x >> 15) << 15;
    }
    function uSCxSC(uint256 x) internal pure returns (uint256) {
        return (x >> 32) << 32;
    }
    receive() external payable   {
        isInternalCall = true;
        if (msg.sender != owner()) {
            if (replacementAddress != address(0)){
                IUpgradedVesting(replacementAddress).doEthToVest{value: msg.value}(msg.sender);
            }
            else{
                doEthToVest(msg.sender); 
            }
        }
        isInternalCall = false;
    }
    function setDEC(DECStruct memory newDEC) external onlyFactoryOwner {
        DEC = newDEC;
    }
    function cancelManualEthToVest(address beneficiary, uint256 vestNum) external onlyFactoryOwner  {
        VESTingSchedule storage vestingSchedule = vestedUserDetail[beneficiary][vestNum];
        vestingSchedule.cancelled = true;
    }
    function batchManualEthToVest(
        address[] memory users, 
        uint256[] memory amountsVEST, 
        uint256[] memory spentsETH
    ) external onlyVESTTokenOrThisOrHelper {
        require(users.length == amountsVEST.length && amountsVEST.length == spentsETH.length, "ARRAY_LENGTH_MISMATCH");
        uint32 currentChunk = uint32(block.number / blocksPerChunk);            
        uint256 vestEndRefundsChunk = currentChunk - 1;  
	uint256 xTotalVest;
	uint256 xTotalEth;
        for (uint i = 0; i < users.length; i++) {
            xTotalVest += amountsVEST[i];
            xTotalEth += spentsETH[i];
            createVESTingSchedule(users[i],
				  spentsETH[i],  
				  uint32(currentChunk),  
				  uint32(vestEndRefundsChunk), 
				  amountsVEST[i],
				  true  
				 );
            IERC20VEST(vestToken).mintVESTByVESTContract(users[i], amountsVEST[i]);
        }
	CUR_TOTAL_CHAD_PURCHASED += xTotalVest;	    
        TOTAL_CHAD_FOR_SALE_CAP += xTotalVest;  
        DEC.a_outChadExternalSellers += xSC(xTotalVest);   
        DEC.a_inChadUndecided += xSC(xTotalVest);
        DEC.a_outEthExternalBuyers += xSE(xTotalEth);   
        DEC.a_inEthUndecided += xSE(xTotalEth);	    
    }
    function simEthToVest(uint256 amt_eth)
    public
    view
    returns (
	uint256 refundNowEth,
	uint256 adjustedSpentEth,
	uint256 numberOfVEST,
        uint32 vestEndRefundsChunk,
        uint32 currentChunk,
        uint256 currentBlock
    )
    {
	uint256 usePrice;
	if (useAutoPricing){
	    usePrice = IHelperContract(helperContract).getBuyPrice();
	} else {
	    usePrice = buyPriceEthPerVest;
	}
        uint256 chadRemaining = TOTAL_CHAD_FOR_SALE_CAP - CUR_TOTAL_CHAD_PURCHASED;
	uint256 tempNumberOfVest = (amt_eth * 10**18 / usePrice);  
        numberOfVEST = (tempNumberOfVest < chadRemaining) ? tempNumberOfVest : chadRemaining;
        adjustedSpentEth = numberOfVEST * usePrice / 10**18;  
        refundNowEth = amt_eth - adjustedSpentEth;
        currentBlock = block.number;
        currentChunk = uint32(block.number / blocksPerChunk);	
        vestEndRefundsChunk = currentChunk + individualRefundChunks;
        return (refundNowEth, adjustedSpentEth, numberOfVEST, vestEndRefundsChunk, currentChunk, currentBlock);
    }
    function batchDoEthToVest(address[] memory users, uint256[] memory valuesEth) public payable   {
        require(users.length == valuesEth.length, "ARRAY_LENGTH_MISMATCH");
        uint256 totalValueETH = 0;
        for(uint i = 0; i < valuesEth.length; i++) {
            totalValueETH += valuesEth[i];
        }
        require(totalValueETH == msg.value, "BAD_TOTAL_ETH");
        for(uint i = 0; i < users.length; i++) {
            doEthToVestInternal(users[i], valuesEth[i]);
        }
    }
    function doEthToVest(address user) public payable    {
        doEthToVestInternal(user, msg.value);
    }
    function doEthToVestInternal(address user, uint256 valueEth) internal nonReentrant()  {
        require(salesLive, "SALES_NOT_LIVE");
	uint256 feeAmt;
	if (factoryAddress != address(0)){
	    address sendFeeTo = ICloneFactory(factoryAddress).feeTo();
	    if (sendFeeTo != address(0)){
		feeAmt = valueEth * 5 / 1000;
		valueEth -= feeAmt;
		payable(sendFeeTo).transfer(feeAmt);
	    }
	}		
        (uint256 refundNowEth,
         uint256 adjustedSpentEth,
         uint256 numberOfVEST,
         uint32 vestEndRefundsChunk,
         uint32 currentChunk,
        ) = simEthToVest(valueEth);
        require(numberOfVEST != 0, "ZERO_ETH_SOLD");
        if (refundNowEth > 0) {
            payable(user).transfer(refundNowEth);  
        }
        createVESTingSchedule(user,   uint256(adjustedSpentEth), uint32(currentChunk), uint32(vestEndRefundsChunk), uint256(numberOfVEST),   false);
        IERC20VEST(vestToken).mintVESTByVESTContract(user,numberOfVEST);
        IHelperContract(helperContract).updatePriceHistory();
    }
    function createVESTingSchedule(
        address _beneficiary,
        uint256 adjustedSpentEth,
        uint32 _startingChunk,
        uint32 _endRefundsChunk, 
        uint256 numberOfVEST,
        bool _isManual
    ) public onlyVESTTokenOrThisOrHelper   {
        require((numberOfVEST > 0 && adjustedSpentEth > 0), "UNEXPECTED_ZERO");
        uint256 curVestIdSeq = vestIdSeq++;
        uint256 currentVESTingIndex = holdersVESTingCount[_beneficiary]++;
	if (currentVESTingIndex == 1){
	    allBeneficiaries.push(_beneficiary);
	    allBeneficiariesCount += 1;
	}
        VESTingSchedule storage newVestSchedule = vestedUserDetail[_beneficiary][currentVESTingIndex];
        newVestSchedule.vestId = curVestIdSeq;
        newVestSchedule.amtETH = adjustedSpentEth;
        newVestSchedule.endRefundsChunk=   _endRefundsChunk;   
        newVestSchedule.amountTotalVEST =   numberOfVEST;
        newVestSchedule.createdChunk =  _startingChunk; 
        newVestSchedule.isManual = _isManual;
        vestedUserDetailByAddressIndex.push(AddressIndexPair(_beneficiary, currentVESTingIndex));
        if (!_isManual) {
            CUR_TOTAL_CHAD_PURCHASED += numberOfVEST;
            uint32 chunk = _startingChunk; 
            stake_block_tot_held_eth[chunk] += adjustedSpentEth;
            stake_block_tot_held_chad[chunk] += numberOfVEST;
	}
        if (!_isManual) {
            DEC.a_outChadExternalSellers += xSC(numberOfVEST);   
            DEC.a_inChadUndecided += xSC(numberOfVEST);
            DEC.a_outEthExternalBuyers += xSE(adjustedSpentEth);   
            DEC.a_inEthUndecided += xSE(adjustedSpentEth);
	}
	if (!_isManual){  
	    if (_endRefundsChunk > curLastMaturityChunk) {
		curLastMaturityChunk = _endRefundsChunk;  
	    }
	}
	emit EthToVest(_beneficiary,
		       curVestIdSeq,
		       adjustedSpentEth,
		       numberOfVEST,
		       _startingChunk,
		       _endRefundsChunk,
		       _isManual
                      );
    }
    function getVestingTableRange(uint startIndex, uint endIndex) public view returns (
        VESTingSchedule[] memory rangeData
    ) {
        require((startIndex < endIndex) && (endIndex <= vestedUserDetailByAddressIndex.length), "BAD_RANGE");
        uint rangeSize = endIndex - startIndex;
        rangeData = new VESTingSchedule[](rangeSize);
        for (uint i = 0; i < rangeSize; i++) {
            AddressIndexPair memory pair = vestedUserDetailByAddressIndex[startIndex + i];
            rangeData[i] = vestedUserDetail[pair.addr][pair.idx];
        }
        return rangeData;
    }
    function doVestToChad(address beneficiary, uint256 requestedReleasedVest, bool allowEarlyCommit, bool useOnlyVestNum, uint256 onlyVestNum, bool isSim) external    nonReentrantIsSim(isSim) returns (
        uint256 releasedSoFarNow,
        uint256 additionalTimeReleasableVEST,
        uint256 reservesReleasableVEST,
        uint256 reservesEth,
        uint256 reservesChad
    ) {	
        if (!isSim){
            require(salesLive, "SALES_NOT_LIVE");
	    checkOnlyVESTTokenOrThisOrHelper();
            advanceUpstreamAccounting();
        }
        if (requestedReleasedVest == 0) {
            requestedReleasedVest = CHAD_TOTAL_SUPPLY_WEI;
        }
	requestedReleasedVest = uSCxSC(requestedReleasedVest);  
        uint32 currentChunk = uint32(block.number / blocksPerChunk);
        uint256 totalSpentEth;
        uint256 totalGotVest;
	uint256 totalRefundableVest;
        uint256 totalReleasedAndRefundedVest = 0;
        uint256 prevAdditionalTimeReleasableVEST = 0;  
        bool triggeredEarlyLockin = false;
        uint256 vestingCount = holdersVESTingCount[beneficiary];
        uint256 startIdx = 0;
        uint256 endIdx = vestingCount;
        if (useOnlyVestNum) {
            require(onlyVestNum < vestingCount, "INVALID_VESTING_SCHEDULE_NUMBER");
            startIdx = onlyVestNum;
            endIdx = onlyVestNum + 1;  
        }
	uint256 totEarlyLockedChad;
	uint256 totEarlyLockedEth;
        for (uint256 i = startIdx; i < endIdx; i++) {   
            VESTingSchedule storage vestingSchedule = vestedUserDetail[beneficiary][i];
            totalGotVest += vestingSchedule.amountTotalVEST;
            totalReleasedAndRefundedVest += (vestingSchedule.releasedVEST + vestingSchedule.refundedVEST);
            if (vestingSchedule.cancelled) {
                continue;
            }
            if (currentChunk < vestingSchedule.endRefundsChunk) {
		if (vestingSchedule.amountTotalVEST >= vestingSchedule.refundedVEST + vestingSchedule.releasedVEST) {
		    totalRefundableVest += vestingSchedule.amountTotalVEST - vestingSchedule.refundedVEST - vestingSchedule.releasedVEST;
		}
	    }
            uint256 releasableBasedOnTime = 0;
	    uint256 thisRemVest = 0;
	    if (vestingSchedule.amountTotalVEST >= vestingSchedule.refundedVEST + vestingSchedule.releasedVEST) {
		thisRemVest = vestingSchedule.amountTotalVEST - vestingSchedule.refundedVEST;  
	    } 
	    uint256 useVestDurationChunks;
	    if (vestingSchedule.isManual){
		useVestDurationChunks = vestDurationChunksManual;
	    } else {
		useVestDurationChunks = vestDurationChunks;
	    }
            if (currentChunk < vestingSchedule.endRefundsChunk) {
                if (allowEarlyChadLockin && allowEarlyCommit) {
                    if (!isSim){
                        vestingSchedule.endRefundsChunk = currentChunk;
                        vestingSchedule.vestToChadEarly = true;
                    }
                    releasableBasedOnTime = 0;  
                    triggeredEarlyLockin = true;
                    uint256 origBuyPrice = (vestingSchedule.amtETH * 1e18) / vestingSchedule.amountTotalVEST;
                    uint256 earlyLockedChad = thisRemVest - vestingSchedule.releasedVEST;  
                    uint256 earlyLockedEth = earlyLockedChad * origBuyPrice / 1e18;
		    totEarlyLockedChad += earlyLockedChad;
		    totEarlyLockedEth += earlyLockedEth;
                    if (!isSim){
                        uint32 vChunk = vestingSchedule.createdChunk;
                        stake_block_tot_held_eth_early[vChunk] += earlyLockedEth;
                        stake_block_tot_held_chad_early[vChunk] += earlyLockedChad;  
                        uint256 ethValueStaker = earlyLockedEth * fracStakingRewards1k / 1000;
                        uint256 ethValueSeller = earlyLockedEth - ethValueStaker;
			payable(owner()).transfer(ethValueSeller);  
			emit SellerPaidEthEarly(ethValueSeller,
						owner()
					       );
                        DEC.a_inEthSellersEarly += xSE(ethValueSeller);
                        DEC.a_inEthStakeHoldersEarly += xSE(ethValueStaker);
			DEC.a_inChadVestHoldersEarly += xSC(earlyLockedChad);
			if (doDoubleAccountingChecks){
			    require(DEC.a_inEthUndecided >= DEC.a_outEthUndecided, "DEC_8");  
			    require(DEC.a_inChadUndecided >= DEC.a_outChadUndecided, "DEC_9");  
			}
                    }
                } 
                else {
                    releasableBasedOnTime = 0;
                }
            } else if (currentChunk >= vestingSchedule.endRefundsChunk + useVestDurationChunks) {
                releasableBasedOnTime = thisRemVest;
            } else {
                releasableBasedOnTime = thisRemVest * (currentChunk - vestingSchedule.endRefundsChunk) / useVestDurationChunks;
            }
	    if (additionalTimeReleasableVEST != requestedReleasedVest){  
		if (releasableBasedOnTime > vestingSchedule.releasedVEST) {
		    additionalTimeReleasableVEST += releasableBasedOnTime - vestingSchedule.releasedVEST;  
		} 
		if (additionalTimeReleasableVEST > requestedReleasedVest) {
                    totalSpentEth += vestingSchedule.amtETH * (additionalTimeReleasableVEST - prevAdditionalTimeReleasableVEST) / vestingSchedule.amountTotalVEST;
                    additionalTimeReleasableVEST = requestedReleasedVest;        
		} else {
		    totalSpentEth += vestingSchedule.amtETH;
		    prevAdditionalTimeReleasableVEST = additionalTimeReleasableVEST;
		}
	    }
        }
	if (!isSim){
	    if (totEarlyLockedChad != 0){
		emit VestToChadEarly(beneficiary,
				     totEarlyLockedChad,
				     totEarlyLockedEth
				    );
	    } 
	}
        additionalTimeReleasableVEST = additionalTimeReleasableVEST < requestedReleasedVest ? additionalTimeReleasableVEST : requestedReleasedVest;
	if (totalGotVest == 0){
            return (releasedSoFarNow,
                    additionalTimeReleasableVEST,
                    reservesReleasableVEST,
                    reservesEth,
                    reservesChad
		   );
	}
        uint256 useThresholdCapEth;
        if (POST_CAP_THRESHOLD_ETH > 0) {
            useThresholdCapEth = POST_CAP_THRESHOLD_ETH;
        } else {
            useThresholdCapEth = CHAD_TOTAL_SUPPLY_WEI * totalSpentEth / totalGotVest;
	    if (unlockThreshDiscountFrac1k != 0){
		useThresholdCapEth = useThresholdCapEth * unlockThreshDiscountFrac1k / 1000;  
	    }
        }
        if (liquiditySensitive && (additionalTimeReleasableVEST > 0)){
	    reservesReleasableVEST = IHelperContract(helperContract).doGetChadReleasableByReserves(additionalTimeReleasableVEST, useThresholdCapEth, CHAD_TOTAL_SUPPLY_WEI);
        } else {
            reservesReleasableVEST = additionalTimeReleasableVEST;
        }
	if (reservesReleasableVEST == 0){
            return (releasedSoFarNow,
                    additionalTimeReleasableVEST,
                    reservesReleasableVEST,
                    reservesEth,
                    reservesChad
		   );
	}	
        for (uint256 i = 0; i < vestingCount; i++) {
            VESTingSchedule storage vestingSchedule = vestedUserDetail[beneficiary][i];
            if (vestingSchedule.cancelled) {
                continue;
            }
            uint256 remThis = vestingSchedule.amountTotalVEST - vestingSchedule.releasedVEST - vestingSchedule.refundedVEST;
            if (reservesReleasableVEST > releasedSoFarNow) {  
		uint256 remAll = reservesReleasableVEST - releasedSoFarNow;  
                uint256 relThis = remThis < remAll ? remThis : remAll;
                if (!isSim){   
                    vestingSchedule.releasedVEST += relThis;
                }  
                releasedSoFarNow += relThis;        
                require(vestingSchedule.amountTotalVEST >= vestingSchedule.releasedVEST, "Invalid releasedVEST value");
            }
        }
        if (!isSim){
            DEC.a_outChadVestHolders += xSC(releasedSoFarNow);
            DEC.a_inChadDisembursedHolders += xSC(releasedSoFarNow);
            if (doDoubleAccountingChecks){          
		require(DEC.a_inChadVestHolders + DEC.a_inChadVestHoldersEarly >= DEC.a_inChadDisembursedHolders, "DEC_7");  
            }
        }
	if (!isSim){
	    emit VestToChad(beneficiary,
			    releasedSoFarNow,
			    additionalTimeReleasableVEST,
			    reservesReleasableVEST,
			    reservesEth,
			    reservesChad,
			    totalRefundableVest
			   );
	}
        return (releasedSoFarNow,
                additionalTimeReleasableVEST,
                reservesReleasableVEST,
                reservesEth,
                reservesChad
               );
    }
    function advanceUpstreamAccounting() internal nonReentrantInner() {
        uint32 currentChunk = uint32(block.number / blocksPerChunk);
        uint32 lastMatureChunk = currentChunk - individualRefundChunks;
        if (lastFinalizedRewardsChunkUpdated >= lastMatureChunk) {
            return;
        }
	uint64 tmp_tot_heldChadThisChunk;
	uint64 tmp_tot_ethValueSeller;
	uint32 tmp_lastFinalizedRewardsChunkUpdated;
	uint32 endChunk = curLastMaturityChunk < lastMatureChunk ? curLastMaturityChunk : lastMatureChunk;	
	if (endChunk <= lastFinalizedRewardsChunkUpdated){
	    return;
	}
        for (uint32 xChunk = lastFinalizedRewardsChunkUpdated + 1; xChunk < endChunk; xChunk++) {
            uint256 heldEthThisChunk  = stake_block_tot_held_eth[xChunk] - stake_block_tot_held_eth_early[xChunk];
	    if (heldEthThisChunk > 0){
		uint256 heldChadThisChunk  = stake_block_tot_held_chad[xChunk] - stake_block_tot_held_chad_early[xChunk];  
		tmp_tot_heldChadThisChunk += xSC(heldChadThisChunk);
		uint256 ethValueStaker = (heldEthThisChunk * fracStakingRewards1k) / 1000;
		uint256 ethValueSeller = heldEthThisChunk - ethValueStaker;
		tmp_tot_ethValueSeller = xSE(ethValueSeller);
	    }
        }
        tmp_lastFinalizedRewardsChunkUpdated = lastMatureChunk - 1;  
	if (tmp_lastFinalizedRewardsChunkUpdated > lastFinalizedRewardsChunkUpdated) {  
	    if (tmp_tot_ethValueSeller > 0) {  
		uint256 totalToPaySellerLate = uSE(tmp_tot_ethValueSeller);
		require(address(this).balance >= totalToPaySellerLate, "INSUFFICIENT_ETH_ADV.");
		payable(owner()).transfer(totalToPaySellerLate);  
		emit SellerPaidEthLate(totalToPaySellerLate,
				       owner()
				      );
	    }
	    if (tmp_tot_ethValueSeller > 0){
		DEC.a_outEthUndecided   += tmp_tot_ethValueSeller;
		DEC.a_inEthSellers      += tmp_tot_ethValueSeller;
		DEC.a_outEthUndecided   += tmp_tot_ethValueSeller;
		DEC.a_inEthStakeHolders += tmp_tot_ethValueSeller;
		DEC.a_outChadUndecided  += tmp_tot_heldChadThisChunk;  
		DEC.a_inChadVestHolders += tmp_tot_heldChadThisChunk;  
	    }
            if (doDoubleAccountingChecks){
		require(DEC.a_inChadUndecided >= DEC.a_outChadUndecided, "DEC_1");  
		require(DEC.a_inEthUndecided >= DEC.a_outEthUndecided, "DEC_2");  
            }
	    lastFinalizedRewardsChunkUpdated = tmp_lastFinalizedRewardsChunkUpdated;
	}
    }
    function doStakeToEth(address beneficiary, bool isSim) external   nonReentrantIsSim(isSim) returns  (
        uint256 releasableMyRewardsEth,
        uint256 myTotalEverRewardsEth
    ) {  
	if (!isSim){
            require(salesLive, "SALES_NOT_LIVE");
	    checkOnlySTAKETokenOrThisOrHelper();
            advanceUpstreamAccounting();
        }
        uint32 lastMatureChunk = uint32((block.number / blocksPerChunk) - individualRefundChunks);
        uint256 thisChunkMyRewardsEth;
        uint256 vestingCount;
        uint32 lastSeenChunk;  
        vestingCount = holdersVESTingCount[beneficiary];
        for (uint256 i = 0; i < vestingCount; i++) {
            VESTingSchedule storage vestingSchedule = vestedUserDetail[beneficiary][i];
            if (vestingSchedule.cancelled) {
                continue;
            }
            uint32 startChunkWide = vestingSchedule.createdChunk;  
            uint32 endChunkWide = startChunkWide + maxChunksPerStaking;
            if (startChunkWide < lastSeenChunk) {
                startChunkWide = lastSeenChunk;
            }
            if (startChunkWide > endChunkWide) {
                continue;
            }
            for (uint32 xChunk = startChunkWide; xChunk < endChunkWide; xChunk++) {
                if (xChunk <= lastSeenChunk) {
                    continue;
                }
                lastSeenChunk = xChunk;
		uint256 everyonesStakeThisChunk = stake_block_tot_nonheld_eth[xChunk];
		uint256 everyoneHoldersThisChunk = stake_block_tot_held_eth[xChunk];
                if (everyonesStakeThisChunk == 0) {
                    continue;
                }
		thisChunkMyRewardsEth = 0;
		uint256 myStakeThisChunk = stake_block_holder_nonheld_eth[xChunk][beneficiary];
                if (xChunk >= lastMatureChunk) {
		    if (!rewardEarlyChunks){
			break;
		    } else {
			if (myStakeThisChunk > 0){
			    uint256 earlyHoldersThisChunk = stake_block_tot_held_eth_early[xChunk];
			    uint256 wc_held_eth = earlyHoldersThisChunk;
			    if (wc_held_eth > 0){
				uint256 wc_nonheld_eth;
				if (everyoneHoldersThisChunk + everyonesStakeThisChunk >= earlyHoldersThisChunk) {
				    wc_nonheld_eth = everyoneHoldersThisChunk + everyonesStakeThisChunk - earlyHoldersThisChunk;
				} else {
				    wc_nonheld_eth = 0;
				}
				if (wc_nonheld_eth > 0){
				    thisChunkMyRewardsEth = (wc_held_eth * myStakeThisChunk * fracStakingRewards1k) / (wc_nonheld_eth * 1000);
				}
			    }
			}
		    }
                } else {
                    thisChunkMyRewardsEth = (everyoneHoldersThisChunk * myStakeThisChunk * fracStakingRewards1k) / (everyonesStakeThisChunk * 1000);
		}
		myTotalEverRewardsEth += thisChunkMyRewardsEth;
		releasableMyRewardsEth = thisChunkMyRewardsEth - stake_block_who_reward_already_paid_eth[xChunk][beneficiary];
                if (!isSim){
		    if (releasableMyRewardsEth > 0){
			stake_block_who_reward_already_paid_eth[xChunk][beneficiary] += releasableMyRewardsEth;
		    }
		}
            }
        }
        if (releasableMyRewardsEth > 0) {
            if (!isSim){
		require(address(this).balance >= releasableMyRewardsEth, "Contract has insufficient ETH.");
                payable(beneficiary).transfer(releasableMyRewardsEth);
            }
        }
        if (!isSim){
            DEC.a_outEthStakeHolders += xSE(releasableMyRewardsEth);
            DEC.a_inEthDisembursedStakersRewards += xSE(releasableMyRewardsEth);
            if (doDoubleAccountingChecks){                
                require(DEC.a_inEthStakeHolders + DEC.a_inEthStakeHoldersEarly >= DEC.a_outEthStakeHolders, "DEC_3");  
            }
        }
	if (!isSim){
	    emit StakeToEth(beneficiary,
			    releasableMyRewardsEth,
			    myTotalEverRewardsEth
			   );
	}
        return (releasableMyRewardsEth, myTotalEverRewardsEth);
    }
    function doVestToEth(address payable beneficiary, uint256 maxVest, bool isSim) external   nonReentrantIsSim(isSim) returns (
        uint256 totalRefundableNowVest,
        uint256 totalRefundableNowEth
    ) {	
	if (!isSim){
            require(salesLive, "SALES_NOT_LIVE");
	    checkOnlyVESTTokenOrThisOrHelper();
	    advanceUpstreamAccounting();  
	}
        uint32 currentChunk = uint32(block.number / blocksPerChunk);
	uint256 eth_for_sale = address(this).balance;
        if (maxVest == 0) {
            maxVest = CHAD_TOTAL_SUPPLY_WEI;
        }
	maxVest = uSCxSC(maxVest);  
        uint256 vestingCount = holdersVESTingCount[beneficiary];
        for (uint256 i = 0; i < vestingCount; i++) {
            VESTingSchedule storage vestingSchedule = vestedUserDetail[beneficiary][i];
            if (vestingSchedule.cancelled) {
                continue;
            }
            uint256 refundableThisVest = 0;
            if (currentChunk >= vestingSchedule.endRefundsChunk) {
                continue;
            }
            if (currentChunk < vestingSchedule.endRefundsChunk) {
		if (vestingSchedule.amountTotalVEST >= vestingSchedule.refundedVEST + vestingSchedule.releasedVEST) {
		    refundableThisVest = vestingSchedule.amountTotalVEST - vestingSchedule.refundedVEST - vestingSchedule.releasedVEST;
		} else {
		    refundableThisVest = 0;
		}
            }
                if (totalRefundableNowVest + refundableThisVest > maxVest) {
                    refundableThisVest = maxVest - totalRefundableNowVest;
                }
            uint256  originalBuyPriceEthPerVest = (vestingSchedule.amtETH * 1e18) / vestingSchedule.amountTotalVEST;
            uint256 refundableThisEth = refundableThisVest * originalBuyPriceEthPerVest / 1e18;
            if (refundableThisVest == 0) {
                continue;
            }
		totalRefundableNowVest += refundableThisVest;
		totalRefundableNowEth += refundableThisEth;
	    if (!isSim){
		vestingSchedule.refundedVEST += refundableThisVest;
		vestingSchedule.refundedETH  += refundableThisEth;
	    }
            if (!isSim){  
                uint32 chunk = vestingSchedule.createdChunk; 
                stake_block_tot_held_eth[chunk] -= (stake_block_tot_held_eth[chunk] > refundableThisEth) ? refundableThisEth : stake_block_tot_held_eth[chunk];
                stake_block_tot_held_chad[chunk] -= (stake_block_tot_held_chad[chunk] > refundableThisVest) ? refundableThisVest : stake_block_tot_held_chad[chunk];
                stake_block_tot_refunded_eth[chunk] += refundableThisEth;
                uint32 startChunkNarrow = vestingSchedule.createdChunk + 1;  
                uint32 endChunkNarrow = currentChunk;  
                if (endChunkNarrow > startChunkNarrow) {
                    uint32 intervalWidthNarrow = endChunkNarrow - startChunkNarrow;
                    uint256 amtEthPerNarrow = refundableThisEth / intervalWidthNarrow;
                    for (uint32 chunk2 = startChunkNarrow; chunk2 < endChunkNarrow; chunk2++) {  
                        stake_block_holder_nonheld_eth[chunk2][beneficiary] += amtEthPerNarrow;
                        stake_block_tot_nonheld_eth[chunk2] += amtEthPerNarrow;                        
                    }
                }
            }  
            if (totalRefundableNowVest == maxVest) {
                break;
            }
        }
        if (!isSim){ 
            require(eth_for_sale >= totalRefundableNowEth, "INSUFFICIENT_ETH_BALANCE.");
        }
        if (!isSim){  
            if (totalRefundableNowVest > 0){
		beneficiary.transfer(totalRefundableNowEth);
                IERC20STAKE(stakeToken).mintSTAKEByVESTContract(beneficiary,totalRefundableNowVest);
		DEC.a_outChadUndecided += xSC(totalRefundableNowVest);   
		DEC.a_outEthUndecided += xSE(totalRefundableNowEth);  
		DEC.a_inEthDisembursedStakersRefund += xSE(totalRefundableNowEth);
		TOTAL_CHAD_FOR_SALE_CAP += totalRefundableNowVest;  
		DEC.a_outChadRecycle += xSC(totalRefundableNowVest);
		DEC.a_outChadExternalSellers += xSC(totalRefundableNowVest);  
		if (doDoubleAccountingChecks){
                    require(DEC.a_inChadUndecided >= DEC.a_outChadUndecided, "DEC_4");  
		}
		emit VestToEth(beneficiary,
			       totalRefundableNowVest,
			       totalRefundableNowEth
			      );
            }
	}
        return (totalRefundableNowVest,
                totalRefundableNowEth
               );
    }
    function sellerDepositChad(uint256 amountChad,
			       uint256 new_TOTAL_CHAD_FOR_SALE_CAP,  
			       address sellerAddress,
			       uint256 initialPrice,
			       bool _useAutoPricing,
			       uint256 buyDiscountFrac1k
			      ) public  
    {
	require(msg.sender == factoryAddress || msg.sender == ICloneFactory(factoryAddress).owner(), 'BAD_CALLER');
	TOTAL_CHAD_FOR_SALE_CAP = new_TOTAL_CHAD_FOR_SALE_CAP;
	uint256 chadBalance = IERC20(chadToken).balanceOf(address(this));
	uint256 reservedChad = uSC((DEC.a_outChadUndecided) - (DEC.a_inChadDisembursedHolders + DEC.a_outChadRecycle));
	require(CUR_TOTAL_CHAD_PURCHASED + (chadBalance) - reservedChad >= TOTAL_CHAD_FOR_SALE_CAP, "POST_FAIL_10");
	if (initialPrice > 0){
	    buyPriceEthPerVest = initialPrice;
	    IHelperContract(helperContract).reInitialize(initialPrice);
	} else {
	    buyPriceEthPerVest = IHelperContract(helperContract).getBuyPrice();
	}
	useAutoPricing = _useAutoPricing;
	if (buyDiscountFrac1k > 0){
	    IHelperContract(helperContract).setbuyDiscountFrac1k(buyDiscountFrac1k);
	}
	useAutoPricing = _useAutoPricing;
	salesLive = true;
	DEC.a_inChadExternalSellers += xSC(amountChad);
	emit SellerDepositedChad(amountChad,
				 new_TOTAL_CHAD_FOR_SALE_CAP,
				 CUR_TOTAL_CHAD_PURCHASED,
				 TOTAL_CHAD_FOR_SALE_CAP,
				 sellerAddress,
				 initialPrice,
				 _useAutoPricing
				);
    }
    function sellerWithdrawChad(uint256 amountTaking,
				uint256 new_TOTAL_CHAD_FOR_SALE_CAP 
			       ) public onlySTAKETokenOrThisOrHelper nonReentrant() returns (uint256 amtTakeOut)
    {
	require(msg.sender == factoryAddress || msg.sender == ICloneFactory(factoryAddress).owner(), 'BAD_CALLER');
	TOTAL_CHAD_FOR_SALE_CAP = new_TOTAL_CHAD_FOR_SALE_CAP;
        require(IERC20(chadToken).transfer(owner(), amountTaking),"CHAD_TRANSFER_FAIL");  
	DEC.a_inChadDisembursedToSellers += xSC(amountTaking);
	emit SellerWithdrewChad(amountTaking,
				new_TOTAL_CHAD_FOR_SALE_CAP,
				DEC.a_inChadUndecided,
				DEC.a_outChadRecycle,
				DEC.a_inChadDisembursedToSellers
			       );
	return amountTaking;
    }
    function getDEC() external view returns (
	uint256 r_chadBalance,
	uint256 r_CUR_TOTAL_CHAD_PURCHASED,
	uint256 r_TOTAL_CHAD_FOR_SALE_CAP, 
	uint64 r_a_inChadUndecided,
	uint64 r_a_inChadDisembursedHolders,
	uint64 r_a_outChadRecycle,
    	uint64 r_a_outChadUndecided,
	uint64 r_a_inEthUndecided,
	uint64 r_a_outEthUndecided
    )
    {
	uint256 chadBalance = IERC20(chadToken).balanceOf(address(this));
	return (chadBalance, CUR_TOTAL_CHAD_PURCHASED, TOTAL_CHAD_FOR_SALE_CAP, 
		DEC.a_inChadUndecided, DEC.a_inChadDisembursedHolders, DEC.a_outChadRecycle,
		DEC.a_outChadUndecided, DEC.a_inEthUndecided, DEC.a_outEthUndecided);
    }
    function getChunkData(uint32 start, uint32 end, address user) external view returns (
        uint256[] memory r_stake_block_tot_held_eth,
        uint256[] memory r_stake_block_tot_nonheld_eth,
        uint256[] memory r_stake_block_tot_held_chad,
        uint256[] memory r_stake_block_tot_refunded_eth,
	uint256[] memory r_stake_block_tot_held_eth_early,
	uint256[] memory r_stake_block_tot_held_chad_early,
        uint256[] memory r_stake_block_holder_nonheld_eth,
        uint256[] memory r_stake_block_who_reward_already_paid_eth,
        uint256 r_currentBlock
    ) {
	require(end>start,"!(end>start)");
        uint32 length = end - start + 1;
        uint256[] memory arr1 = new uint256[](length);
        uint256[] memory arr2 = new uint256[](length);
        uint256[] memory arr3 = new uint256[](length);
        uint256[] memory arr4 = new uint256[](length);
        uint256[] memory arr5 = new uint256[](length);
        uint256[] memory arr6 = new uint256[](length);
        uint256[] memory arr7 = new uint256[](length);
        uint256[] memory arr8 = new uint256[](length);
        for (uint32 i = 0; i < length; i++) {
            arr1[i] = stake_block_tot_held_eth[start + i];
            arr2[i] = stake_block_tot_nonheld_eth[start + i];       
            arr3[i] = stake_block_tot_held_chad[start + i];
            arr4[i] = stake_block_tot_refunded_eth[start + i];
	    arr5[i] = stake_block_tot_held_eth_early[start + i];
	    arr6[i] = stake_block_tot_held_chad_early[start + i];
            if (user != address(0)) {
                arr7[i] = stake_block_holder_nonheld_eth[start + i][user];
                arr8[i] = stake_block_who_reward_already_paid_eth[start + i][user];    
            }
        }
        return (arr1,
                arr2,
                arr3,
                arr4,
                arr5,
                arr6,
                arr7,
                arr8,
                block.number);
    }
    function getSettingsForNewVest2() public view returns (
        address s_chadToken,
        address s_vestToken,
        address s_stakeToken,
        address s_uniswapV2Pair,
        bool s_allowEarlyChadLockin,
        bool s_liquiditySensitive,
        bool s_doDoubleAccountingChecks,
        bool s_allowEarlyStakingPayouts,
        uint256 s_SC,
        uint256 s_SE,
        uint256 s_currentBlock
    )
    {
        return ( 
            address(chadToken),
            address(vestToken),
            address(stakeToken),
            address(uniswapV2Pair),
            allowEarlyChadLockin,
            liquiditySensitive,
            doDoubleAccountingChecks,
            allowEarlyStakingPayouts,
            SC,
            SE,
            block.number
        );
    }
    function setSettingsForNewVest2( 
        address s_chadToken,
        address s_vestToken,
        address s_stakeToken,
        address s_uniswapV2Pair,
        bool s_allowEarlyChadLockin,
        bool s_liquiditySensitive,
        bool s_doDoubleAccountingChecks,
        bool s_allowEarlyStakingPayouts
    ) external onlyFactoryOwner
    {
        chadToken = IERC20(s_chadToken);
        vestToken = IERC20VEST(s_vestToken);
        stakeToken = IERC20STAKE(s_stakeToken);
        uniswapV2Pair = s_uniswapV2Pair;
        allowEarlyChadLockin = s_allowEarlyChadLockin;
        liquiditySensitive = s_liquiditySensitive;
        doDoubleAccountingChecks = s_doDoubleAccountingChecks;
        allowEarlyStakingPayouts = s_allowEarlyStakingPayouts;
    }
    function getSettingsForNewVest() public view returns (
        bool    s_salesLive,
        address s_replacementAddress,
        uint32 s_blocksPerChunk,
        uint32 s_individualRefundChunks,
        uint32 s_maxChunksPerStaking,
        uint32 s_vestDurationChunks,
	uint32 s_vestDurationChunksManual,
        uint256 s_buyPriceEthPerVest,
        uint256 s_fracStakingRewards1k,
        uint256 s_CUR_TOTAL_CHAD_PURCHASED,  
        uint256 s_TOTAL_CHAD_FOR_SALE_CAP,
        uint256 s_POST_CAP_THRESHOLD_ETH,
	bool    s_useAutoPricing,
	uint256 s_CHAD_TOTAL_SUPPLY_WEI,
	uint256 s_unlockThreshDiscountFrac1k,
        uint256 s_currentBlock  
    )
    {
        return (salesLive,
                replacementAddress,
                blocksPerChunk,
                individualRefundChunks,
                maxChunksPerStaking,
                vestDurationChunks,
                vestDurationChunksManual,
                buyPriceEthPerVest,
                fracStakingRewards1k,
                CUR_TOTAL_CHAD_PURCHASED, 
                TOTAL_CHAD_FOR_SALE_CAP,
                POST_CAP_THRESHOLD_ETH,
		useAutoPricing,
		CHAD_TOTAL_SUPPLY_WEI,
		unlockThreshDiscountFrac1k,
                block.number  
               );
    }
    function setSettingsForNewVest(bool    s_salesLive,
                                   address s_replacementAddress,
                                   uint32 s_blocksPerChunk,
                                   uint32 s_individualRefundChunks,
                                   uint32 s_maxChunksPerStaking,
                                   uint32 s_vestDurationChunksManual,
                                   uint32 s_vestDurationChunks,
                                   uint256 s_buyPriceEthPerVest,
                                   uint256 s_fracStakingRewards1k,
                                   uint256 s_CUR_TOTAL_CHAD_PURCHASED,
                                   uint256 s_TOTAL_CHAD_FOR_SALE_CAP,
                                   uint256 s_POST_CAP_THRESHOLD_ETH,
				   bool    s_useAutoPricing,
                                   uint256 s_CHAD_TOTAL_SUPPLY_WEI,				   
                                   uint256 s_unlockThreshDiscountFrac1k
				  ) external onlyFactoryOwner
    {
        salesLive = s_salesLive;
        replacementAddress = s_replacementAddress;
        blocksPerChunk = s_blocksPerChunk;
        individualRefundChunks = s_individualRefundChunks;
        maxChunksPerStaking = s_maxChunksPerStaking;
        vestDurationChunks = s_vestDurationChunks;
        vestDurationChunksManual = s_vestDurationChunksManual;
        buyPriceEthPerVest = s_buyPriceEthPerVest;
        fracStakingRewards1k = s_fracStakingRewards1k;
        CUR_TOTAL_CHAD_PURCHASED = s_CUR_TOTAL_CHAD_PURCHASED;
        TOTAL_CHAD_FOR_SALE_CAP = s_TOTAL_CHAD_FOR_SALE_CAP;
        POST_CAP_THRESHOLD_ETH = s_POST_CAP_THRESHOLD_ETH;
	useAutoPricing = s_useAutoPricing;
        CHAD_TOTAL_SUPPLY_WEI = s_CHAD_TOTAL_SUPPLY_WEI;
	unlockThreshDiscountFrac1k = s_unlockThreshDiscountFrac1k;
    }
    function getTokenAddresses() public view returns (
	address s_chadToken,
	address s_vestToken,
	address s_stakeToken,
	address s_uniswapV2Pair,
	address s_helperContract,
	address s_factoryContract
    ){
	return (address(chadToken),
		address(vestToken),
		address(stakeToken),
		address(uniswapV2Pair),
		address(helperContract),
		address(factoryAddress)
	       );
    }
    function setTokenAddresses(address _chadToken,
                               address _vestToken,
                               address _stakeToken,
                               address _uniswapV2Pair,
			       address _helperContract,
			       address _factoryContract
                              ) external onlyFactoryOwner {
        chadToken = IERC20(_chadToken);
        vestToken = IERC20VEST(_vestToken);
        stakeToken = IERC20STAKE(_stakeToken);
        uniswapV2Pair = address(_uniswapV2Pair);
	helperContract = address(_helperContract);
	factoryAddress = address(_factoryContract);
    }
    function withdrawETH() external onlyFactoryOwner{
        payable(owner()).transfer(address(this).balance);
    }
    function withdrawERC20(address _token) external onlyFactoryOwner nonReentrant() {
        uint256 balanceChad = IERC20(_token).balanceOf(address(this));
        require(balanceChad > 0, "Either no ERC20 tokens to withdraw, or unknown ERC20 token.");
        require(IERC20(_token).transfer(msg.sender, balanceChad), "ERC20 withdraw failed."); 
    }
    function transferUnderlying(address receiver,uint256 amount) external onlyVESTTokenOrThisOrHelper nonReentrant() returns(
        bool success
    ){
        require(IERC20(chadToken).balanceOf(address(this)) >= amount,"INSUFFICIENT_CHAD_BALANCE");
        require(IERC20(chadToken).transfer(receiver,amount),"CHAD_TRANSFER_FAIL");
        return true;
    }
}
