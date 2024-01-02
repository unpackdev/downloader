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
 
abstract contract Context {
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
abstract contract Ownable is Context {
    address private _owner;
    error OwnableUnauthorizedAccount(address account);
    error OwnableInvalidOwner(address owner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor(address initialOwner) {
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
        return _owner;
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
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
library Clones {
    error ERC1167FailedCreateClone();
    function clone(address implementation) internal returns (address instance) {
        assembly {
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        if (instance == address(0)) {
            revert ERC1167FailedCreateClone();
        }
    }
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        if (instance == address(0)) {
            revert ERC1167FailedCreateClone();
        }
    }
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt
    ) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}
interface IERC20 {
    function symbol() external view returns (string memory);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}
interface IBasedMarket {
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
		       ) external;
    function finishInitialize(address _vestToken,
			      address _stakeToken,
			      address _uniswapV2Pair,
			      address _WETH_ADDRESS,
			      address _helperContract,
			      uint256 firstPriceEth
			     ) external;
    function sellerDepositChad(uint256 amountChad,
			       uint256 new_TOTAL_CHAD_FOR_SALE_CAP,
			       address sellerAddress,
			       uint256 initialprice,
			       bool _useAutoPricing,
			       uint256 buyDiscountFrac1k
			      ) external;
    function sellerWithdrawChad(uint256 amountChad,
				uint256 new_TOTAL_CHAD_FOR_SALE_CAP
			       ) external returns (uint256 amountChadOut);
    function owner() external returns (address);
    function DEC() external returns (DECStruct calldata);
    function CUR_TOTAL_CHAD_PURCHASED() external returns (uint256);
    function TOTAL_CHAD_FOR_SALE_CAP() external returns (uint256);
    function getDEC() external view returns (uint256 r_chadBalance, uint256 r_CUR_TOTAL_CHAD_PURCHASED, uint256 r_TOTAL_CHAD_FOR_SALE_CAP,
					     uint64 r_a_inChadUndecided, uint64 r_a_inChadDisembursedHolders, uint64 r_a_outChadRecycle,
					     uint64 r_a_outChadUndecided, uint64 r_a_inEthUndecided, uint64 r_a_outEthUndecided);
}
struct DECStruct {
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
interface IBasedERC20 {
    function initialize(
        address _creatorOwner,
        address _factoryAddress,
        address _vestingContract,
        string calldata name,
        string calldata symbol
    ) external;
}
interface IBasedHelperContract {
    function initialize(
	address _currentOwner,
    	address _factoryAddress,
	address _vestingContract,
	address _vestToken,
	address _chadToken,
	address _stakeToken,
	address _uniswapV2Pair,
	address _WETH_ADDRESS,
	uint256 firstPriceEth
    ) external;
}
interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}
interface IUniswapV2Router {
    function WETH() external pure returns (address);
}
interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);    
}
contract BasedMarketFactory is Ownable {
    address public basedAssuranceCloneable;
    address public basedVestTokenCloneable;
    address public basedStakeTokenCloneable;
    address public basedHelperContractCloneable;
    mapping(address => mapping(address => address)) public getMarket;
    address[] public allMarkets;
    address public feeTo;
    bool public capFromScratch;
    event MarketCreated(address erc20Address,
			address ownerAddress,
			address marketContract,
			address vestToken,
			address stakeToken,
			uint256 firstPriceEth,
			uint256 allMarketsLength
		       );
    event StartAddLiquidity(address erc20Address,
			    address ownerAddress,
			    uint256 amountTokens,
			    address Market,
			    uint64 DEC_a_inChadUndecided,
			    uint64 DEC_a_inChadDisembursedHolders,
			    uint64 DEC_a_outChadRecycle
			   );
    event AddLiquidityTransferFrom(address erc20Address,
				   address ownerAddress,
				   uint256 amountTokens,
				   uint256 amtKeep,
				   uint256 chadBalance,
				   uint256 CUR_TOTAL_CHAD_PURCHASED,
				   uint256 old_TOTAL_CHAD_FOR_SALE_CAP,
				   uint256 new_TOTAL_CHAD_FOR_SALE_CAP,
				   bool capFromScratch
				  );
    event StartRemoveLiquidity(uint256 CUR_TOTAL_CHAD_PURCHASED,
			       uint256 chadBalance,
			       uint256 old_TOTAL_CHAD_FOR_SALE_CAP,
			       uint256 amountTaking,
			       uint64 DEC_a_inChadUndecided,
			       uint64 DEC_a_inChadDisembursedHolders,
			       uint64 DEC_a_outChadRecycle
			      );	
    event RemoveLiquidity(address erc20Address,
			  address ownerAddress,
			  uint256 amountTakingRequested,
			  uint256 amountTaking,
			  uint256 maxTake,
			  uint256 old_TOTAL_CHAD_FOR_SALE_CAP,
			  uint256 new_TOTAL_CHAD_FOR_SALE_CAP,
			  bool capFromScratch
			 );
    struct FactoryDefaults {
	uint256 unlockThreshDiscountFrac1k;
	bool useAutoPricing;
	uint256 CHAD_TOTAL_SUPPLY_WEI;
	uint256 POST_CAP_THRESHOLD_ETH;
	bool allowEarlyChadLockin;
	bool rewardEarlyChunks;
	bool allowEarlyStakingPayouts;
	bool doDoubleAccountingChecks;
    }
    FactoryDefaults public factoryDefaults = FactoryDefaults({
	unlockThreshDiscountFrac1k: 900,
	useAutoPricing: true,
	CHAD_TOTAL_SUPPLY_WEI: 10_400_000_000 * 1e18,
	POST_CAP_THRESHOLD_ETH: 0,
	allowEarlyChadLockin: true,
	rewardEarlyChunks: true,
	allowEarlyStakingPayouts: true,
	doDoubleAccountingChecks: false
    });
    constructor(address _basedAssuranceCloneable,
		address _basedVestTokenCloneable,
		address _basedStakeTokenCloneable,
		address _basedHelperContractCloneable
	       )  Ownable(msg.sender)
    {
        basedAssuranceCloneable = _basedAssuranceCloneable;
	basedVestTokenCloneable = _basedVestTokenCloneable;
	basedStakeTokenCloneable = _basedStakeTokenCloneable;
	basedHelperContractCloneable =_basedHelperContractCloneable;
	capFromScratch = true;
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
    function addBasedLiquidity(address erc20Address,
			       uint256 amountAdding,
			       uint256 initialPrice,
			       bool _useAutoPricing,
			       uint256 buyDiscountFrac1k  
			      ) public
    {	
	address ownerAddress = msg.sender;
	if (getMarket[erc20Address][ownerAddress] == address(0)) {
            createMarket(erc20Address, ownerAddress);
	}
	address marketAddress = getMarket[erc20Address][ownerAddress];
	require(marketAddress != address(0), "MARKET_DOES_NOT_EXIST");
	require(msg.sender == IBasedMarket(marketAddress).owner(), "BAD_SELLER");
	require(IERC20(erc20Address).balanceOf(address(ownerAddress)) >= amountAdding, "YOUR_BALANCE_TOO_LOW");
	(uint256 chadBalance, uint256 CUR_TOTAL_CHAD_PURCHASED, uint256 old_TOTAL_CHAD_FOR_SALE_CAP,
	 uint64 DEC_a_inChadUndecided, uint64 DEC_a_inChadDisembursedHolders, uint64 DEC_a_outChadRecycle,
	  ,  ,  ) = IBasedMarket(marketAddress).getDEC();
	emit StartAddLiquidity(erc20Address, ownerAddress, amountAdding, getMarket[erc20Address][ownerAddress],
			       DEC_a_inChadUndecided, DEC_a_inChadDisembursedHolders, DEC_a_outChadRecycle);
	require((DEC_a_inChadUndecided) >= (DEC_a_inChadDisembursedHolders + DEC_a_outChadRecycle), 'PRE_FAIL_6');
	IERC20(erc20Address).transferFrom(ownerAddress, marketAddress, amountAdding);
	if (initialPrice > 0){
	    buyDiscountFrac1k = 1000;
	}
	uint256 minKeep = uSC((DEC_a_inChadUndecided) - (DEC_a_inChadDisembursedHolders + DEC_a_outChadRecycle));
	chadBalance = IERC20(erc20Address).balanceOf(marketAddress);  
	uint256 newGap;
	if (chadBalance >= minKeep){
	    newGap = chadBalance - minKeep;
	} else {
	    newGap = 0;  
	}
	uint256 new_TOTAL_CHAD_FOR_SALE_CAP = CUR_TOTAL_CHAD_PURCHASED + newGap;
	emit AddLiquidityTransferFrom(erc20Address,
				      ownerAddress,
				      amountAdding,
				      minKeep,
				      chadBalance,
				      CUR_TOTAL_CHAD_PURCHASED,
				      old_TOTAL_CHAD_FOR_SALE_CAP,
				      new_TOTAL_CHAD_FOR_SALE_CAP,
				      capFromScratch
				     );
	IBasedMarket(marketAddress).sellerDepositChad(amountAdding,
						      new_TOTAL_CHAD_FOR_SALE_CAP,
						      ownerAddress,
						      initialPrice,
						      _useAutoPricing,
						      buyDiscountFrac1k
						     );
    }
    function removeBasedLiquidity(address erc20Address,
				  uint256 amountTaking
				 ) public
    {
	address marketAddress = getMarket[erc20Address][msg.sender];
	require(marketAddress != address(0), "MARKET_DOES_NOT_EXIST");
	require(msg.sender == IBasedMarket(marketAddress).owner(), "BAD_SELLER");
	uint256 amountTakingRequested = amountTaking;
	(uint256 chadBalance, uint256 CUR_TOTAL_CHAD_PURCHASED, uint256 old_TOTAL_CHAD_FOR_SALE_CAP,
	 uint64 DEC_a_inChadUndecided, uint64 DEC_a_inChadDisembursedHolders, uint64 DEC_a_outChadRecycle,
	  ,  ,  ) = IBasedMarket(marketAddress).getDEC();
	emit StartRemoveLiquidity(CUR_TOTAL_CHAD_PURCHASED,
				  chadBalance,
				  old_TOTAL_CHAD_FOR_SALE_CAP,
				  amountTaking,
				  DEC_a_inChadUndecided,
				  DEC_a_inChadDisembursedHolders,
				  DEC_a_outChadRecycle
				 );	
	require((DEC_a_inChadUndecided) >= (DEC_a_inChadDisembursedHolders + DEC_a_outChadRecycle), 'PRE_FAIL_3');
	uint256 new_TOTAL_CHAD_FOR_SALE_CAP;
	uint256 maxTake;
	uint256 minKeep = uSC((DEC_a_inChadUndecided) - (DEC_a_inChadDisembursedHolders + DEC_a_outChadRecycle));	
	if (chadBalance >= minKeep){
	    maxTake = chadBalance - minKeep;	    
	}
	if (amountTaking > maxTake){
	    amountTaking = maxTake;
	}
	new_TOTAL_CHAD_FOR_SALE_CAP = CUR_TOTAL_CHAD_PURCHASED;
	if (amountTaking > 0){
	    new_TOTAL_CHAD_FOR_SALE_CAP += (maxTake - amountTaking);
	}	
	require(CUR_TOTAL_CHAD_PURCHASED + (chadBalance - amountTaking) - minKeep >= new_TOTAL_CHAD_FOR_SALE_CAP, "POST_FAIL_REM");
	emit RemoveLiquidity(erc20Address,
			     msg.sender,
			     amountTakingRequested,
			     amountTaking,
			     maxTake,
			     old_TOTAL_CHAD_FOR_SALE_CAP,
			     new_TOTAL_CHAD_FOR_SALE_CAP,
			     capFromScratch
			    );
	IBasedMarket(marketAddress).sellerWithdrawChad(amountTaking,						       
						       new_TOTAL_CHAD_FOR_SALE_CAP 
						      );  
    }
    function computeMarketAddress(address erc20Address,
				  address creatorAddress
				 ) public view
    returns (
	address MarketAddress   
    )
    {
	(address a0, address a1) = (erc20Address, creatorAddress);		
	bytes32 salt = keccak256(abi.encodePacked(a0, a1));	
	return Clones.predictDeterministicAddress(basedAssuranceCloneable, salt, creatorAddress);
    }
    function createMarket(address erc20Address,
			  address ownerAddress
			 ) public
    {
	require(ownerAddress == msg.sender, 'msg.sender != ownerAddress');
	(address a0, address a1) = (erc20Address, ownerAddress);
	require(a0 != a1, 'Addresses identical.');
	require(a0 != address(0), 'Zero address.');
	require(a1 != address(0), 'Zero address.');
	uint256 firstPriceEth;
	address wethAddress = IUniswapV2Router(address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D)).WETH();
	address pairAddress = IUniswapV2Factory(address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f)).getPair(erc20Address, wethAddress);
	require((pairAddress != address(0)), "MUST_CREATE_UNISWAP_PAIR_FIRST");
	if (pairAddress != address(0)){
	    (uint256 reserves_tok0, uint256 reserves_tok1,) = IUniswapV2Pair(pairAddress).getReserves();	
	    (uint256 reservesChad, uint256 reservesEth) = (address(erc20Address) < wethAddress) ? (reserves_tok0, reserves_tok1) : (reserves_tok1, reserves_tok0);
	    require(reservesChad > 0, "MUST_ADD_LIQUIDITY_TO_UNISWAP_PAIR_FIRST");
	    if (reservesChad > 0){	    
		firstPriceEth = reservesEth * (10**18) / reservesChad;		
	    }
	}
	string memory symbol = IERC20(erc20Address).symbol();
	bytes32 salt = keccak256(abi.encodePacked(a0, a1));
	address marketContract = Clones.cloneDeterministic(basedAssuranceCloneable, salt);
	IBasedMarket(marketContract).initialize(ownerAddress,      
						address(this),     
						erc20Address,      
						2385,              
						21 * 3,            
						21 * 3,            
						365 * 3,           
						365 * 3 * 8 / 12,  
						10 * (10**1),      
						factoryDefaults.unlockThreshDiscountFrac1k,
						factoryDefaults.useAutoPricing,
						10_400_000_000 * 10**18,  
						factoryDefaults.POST_CAP_THRESHOLD_ETH,
						factoryDefaults.allowEarlyChadLockin,
						factoryDefaults.rewardEarlyChunks,
						factoryDefaults.allowEarlyStakingPayouts,
						factoryDefaults.doDoubleAccountingChecks
					       );
	address vestToken = Clones.cloneDeterministic(basedVestTokenCloneable, salt);
	IBasedERC20(vestToken).initialize(ownerAddress,
					  address(this),
					  marketContract,
					  string(abi.encodePacked(symbol, "VEST")),
					  string(abi.encodePacked(symbol, "VEST"))
					 );
	address stakeToken = Clones.cloneDeterministic(basedStakeTokenCloneable, salt);
	IBasedERC20(stakeToken).initialize(ownerAddress,
					   address(this),  
					   marketContract,
					   string(abi.encodePacked(symbol, "STAKE")),
					   string(abi.encodePacked(symbol, "STAKE"))
					  );
	address helperContract = Clones.cloneDeterministic(basedHelperContractCloneable, salt);
	IBasedHelperContract(helperContract).initialize(ownerAddress,
    							address(this),
							marketContract,
							vestToken,
							erc20Address,
							stakeToken,
							pairAddress,
							wethAddress,
							firstPriceEth
						       );
	IBasedMarket(marketContract).finishInitialize(vestToken,
						      stakeToken,
						      pairAddress,
						      wethAddress,
						      helperContract,
						      firstPriceEth
						     );
	getMarket[a0][a1] = marketContract;
	getMarket[a1][a0] = marketContract;
	allMarkets.push(marketContract);
	emit MarketCreated(erc20Address,
			   ownerAddress,
			   marketContract,
			   vestToken,
			   stakeToken,
			   firstPriceEth,
			   allMarkets.length
			  );
    }
    function setCloneableContracts(
	address _basedAssuranceCloneable,
	address _basedVestTokenCloneable,
	address _basedStakeTokenCloneable,
	address _basedHelperContractCloneable
    ) 
    public onlyOwner
    {
	basedAssuranceCloneable = _basedAssuranceCloneable;
	basedVestTokenCloneable = _basedVestTokenCloneable;
	basedStakeTokenCloneable = _basedStakeTokenCloneable;
	basedHelperContractCloneable = _basedHelperContractCloneable;
    }
    function getCloneableContracts() 
    public 
    view 
    returns (
	address s_basedAssuranceCloneable, 
	address s_basedVestTokenCloneable, 
	address s_basedStakeTokenCloneable, 
	address s_basedHelperContractCloneable
    ) 
    {
	return (
            basedAssuranceCloneable, 
            basedVestTokenCloneable, 
            basedStakeTokenCloneable, 
            basedHelperContractCloneable
	);
    }
    function setCapFromScratch(bool _capFromScratch) public onlyOwner{
	capFromScratch = _capFromScratch;
    }
    function setFeeTo(address _feeTo) public onlyOwner{
	feeTo = _feeTo;
    }
    function setFactoryDefaults(FactoryDefaults memory newDefaults) public onlyOwner {
	factoryDefaults = newDefaults;
    }
    function getFactoryDefaults() public view returns (FactoryDefaults memory) {
	return factoryDefaults;
    }
}
