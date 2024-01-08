// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^~^^~^~~^~^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^|>r)L}cxixxtj{?vr>\^^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^>LiywPaaww22eIIVFFFooolysi}*>|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^=cFE6EkPaaZw22eIIVFFooolyyysssssuucv>^~^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|7wHpU9EkPaaww2e%IVFFooolyyssssszzuuuuuux*\^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^~~>sm8dSU5EkPaZw22eIIFFooolyysssszuuuuuuuuuuuii}r^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^^=l8gDdSU9EkPaZww2e%IFFFoolysssszuuuuuuuuuuuuuuiii7>^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^cQ0gmdSU6EkPaaww2e%IFFFoolysssszuuuuuuuuuiiiiiiiiiii7=~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^<ag0gQRpSU5kPPaZw22%IVFFoolyyssszuuuuuuuuiiiiiiiiiiiiiixr^^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^L$ggggDdSU6EkPaaww2e%IVFFoolyyssszuuuuuuuiiiiiiiiiiiiiiiix?|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*QggggQ$#SU9EkPaZww2eIIVFooolysssszuuuuuuuiiiiiiiiiiiiiiiiiiL^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~^~*Rggggg8R#SU5EkPaZww2eIIFFooolyyssszuuuuuuuiiiiiiiiiiiiiiiiiiiv^~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~\Uggggggmb#UU5kkPaZww2eIIVFFoolyyssszuuuuuuuiiiiiiiiiiiiiiiiiiixr~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~ogggggggmR#SU9EkPaaww2e%IVFFoolyyssszuuuuuuuuiiiiiiiiiiiiiiiiiiic=~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ~~~^~~^=>\^^~^==|~~~|==^/=>so%SgggwziixcjJ}ia}LL??7iFFFoool?JssszuuuxvrrvxitrrrrrrrrrLi?rrr>r=\~~~~~|>=^~~~^==^~~~/=\^^~    //
//    ~~~~igWM&NNS^<NWu~~~sWW~6WN=\; .ugv^~;  ;!!<P` .;;, `)FFoor .tssszJ; .;;. ;7___` `___ri<;_  v&H~~^wBW&NWQ*~iWW8<~~kWb~^~    //
//    ~~~~NWU^~\y?^<NWi~~~sWW~6WNggg, ~ggQDw  s5kkP` ~w2I; :FFFi.  ;sssi, ;xuui=viiii; ,iiiiiiiL  v>~^^IW&)^|eWBriWWWQ>~PW#~~~    //
//    ~~~~FNW02J\~~<NWi~~~sWW~6WE!;, ^pggg8a  y6EkP` ,\|;` vIFF_ ~, =ysr  Juuuuuuuuuu; ,uuuuuuu7  vr~^\BWu^^~^QWwiWgkW&=wW#~~~    //
//    ~~~~~^)oDNW8=<NWi~~~sWW^6W0EPF; ;SgggP  lU9Ek. -r, ,u%II) `*^ `?y*  {zzuuuuuuuu; ,uuuuuuu7  )r~^>NWi~^~~RWkiWQ^IW0SW#~~~    //
//    ~~~~r\~^~rBWy\&Wo~~^2WN^6WNggg*  lgggE  oU65E. ^au, ;%%z, _;;, ,yu, ;iszi*iuuuu; ,uuuuuuu{  )r^~^RWU^~~rNWiiWQ^^IWWW#~~~    //
//    ~~^>NNRkkgW&>^cNNSw#WNu~6WN,,``;igggg6  FSU65. ^Pal" ^F; ~FFFi. rli~` ,, .\zuuu; "uuuuu!..  =#w^~>&W0PUNWl^iWQ^~~kWW#~~~    //
//    ~~~~*iIZwFJ/~^~ru2a%i>^~LyoPP5mggggggQawq#SU6yzFPaaFiioixlIVFFiJiolliL**LussszzjLJzzzzsjLLLLiyi^~~|}FZws*~~ryc^~~^iy7^~~    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~VggggggggggggmR#SU65EkPPaawww22e%IVFFFoooollyyyssssssssssssssyysu<^~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~>HggggggggggggmR#SUU9EkkPaaZww222%IIVFFFFoooollyyyyyyyyyyyyyllly)^^~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~^vDg0ggggggggggm$dqSU65EkPPaaZww222e%IIVFFFFooooooooooooooooooo}^~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~Lg000g0000000gQ$d#SUU9EkkPPaaZww222e%%IIVVFFFFFFFFFFFFFFFFFFu|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~^~Jm000000000000gmRdpSUU9EkkPPaaaZww2222e%%IIIIVVVVVIIIIIIIVx\~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*S000000000000gQDR#qSUU9EEkkPPaaaZwww22222eeeeeeeeee22e%7^^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|ig000000000000gQDRdpSUU65EEkkPPPaaaZZwwwwwwwwwwwwwwwyr^^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^~*k00&&000000000gQDRd#qSUU65EEkkkPPPPaaaaaaaaaaaaaIL|^^^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^rFg&&&&&&&&&&&&0g8DRd#qSUUU695EEkkkkkkkkkkkkk%7^^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^rsd&&&&&&&&&&&&&0gQDRbH#qSSUUUUU66666666Esv^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^>zU0&&&&&&&&&&&&&0gQmD$RddH#######ks?\~^~^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^vuZd&&&&BBBBBBBBB&&&&&&&&QUy}>^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^=*Jz2kUR8g00gQ$qEwy}r|^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^~^^~^~~^~^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/// @artist: ThankYouX x mpkoz
/// @title: Subtraction
/// @author: manifold.xyz

import "./Proxy.sol";
import "./Address.sol";
import "./StorageSlot.sol";

contract Subtraction is Proxy {

    constructor(address signingAddress) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        address collectionImplementation = 0xCE2462042c6bBF7a5fBdD1c623f181589Be30569;
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = collectionImplementation;
        Address.functionDelegateCall(
            collectionImplementation,
            abi.encodeWithSignature("initialize(address,uint16,uint256,uint16,uint16,address)", 0x6826C4c51f4855D0280E99f646C5Ef43EDb3848E, 512, 512000000000000000, 2, 1, signingAddress)
        );
    }

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
     function implementation() public view returns (address) {
        return _implementation();
    }

    function _implementation() internal override view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

}