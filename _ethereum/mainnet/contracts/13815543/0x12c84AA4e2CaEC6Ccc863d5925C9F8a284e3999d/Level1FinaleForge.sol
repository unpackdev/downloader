// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                 //
//                                                                                                 //
//                                           .....                                                 //
//                                     -+*%@@@@@@@@@#*++=-:                                        //
//                                 .=#@@@@@@@@@@@@@@@@@@@@@@#+:                                    //
//                               -#@@@@@@@@@@@@@@@@@@@@@@@@@@@@%-                                  //
//                             =@@@@@@@@@@%*+==----==*#@@@@@@@@@@%-                                //
//                           :%@@@@@@@@*-.              :+%@@@@@@@@#.                              //
//                          =@@@@@@@@+.                    -#@@@@@@@@+                             //
//                         *@@@@@@@+.                        :#@@@@@@@%.                           //
//                        *@@@@@@@:                            =@@@@@@@@-                          //
//                       +@@@@@@%.                              :@@@@@@@@=                         //
//                      -@@@@@@@.                                -@@@@@@@@=                        //
//                      %@@@@@@=                                  #@@@@@@@@=                       //
//                     -@@@@@@@.                                  -@@@@@@@@@-                      //
//                     #@@@@@@#                                    %@@@@@@@@@.                     //
//                     @@@@@@@*                                    =@@@@@@@@@*                     //
//                     @@@@@@@*                                     @@@@@@@@@@.                    //
//                    .@@@@@@@*                                     *@@@@@@@@@=                    //
//                    .@@@@@@@#                                     -@@@@@@@@@#                    //
//                    .@@@@@@@%                                     .@@@@@@@@@@                    //
//                     @@@@@@@@                                     .@@@@@@@@@@.                   //
//                     %@@@@@@@.                                    -@@@@@@@@@@:                   //
//                     %@@@@@@@-                                    +@@@@@@@@@@-                   //
//                    :@@@@@@@@*                                    #@@@@@@@@@@-                   //
//                   =@@@@@@@@@@           .+%@@%++@@@%+.          .@@@@@@@@@@@:                   //
//                  . @@@@@@@@@@=         +@#+-:.   .:=%@=         =@@@@@@@@@@@:                   //
//                   -@@@@@@@@@@%        -@:            -@.        @@@@@@@@@@@@:                   //
//                   *@@@@@@@@@@@#       *=              #:       #@@@@@@@@@@@@:                   //
//                   *@@@@@@@@@@@@%:     ::     .--:     :      .%@@@@@@@@@@@@@=                   //
//                   =@@@@@@@@@@@@@@+           =@@#       .   +@@@@@@@@@@@@@@@*                   //
//                   -@@@@@@@@@@@@@@@%=.-+       *@.      :@##@@@@@@@@@@@@@@@@@@                   //
//                   +@@@@@@@@@@@@@@@@@@@@=  .==:    -+=:-%@@@@@@@@@@@@@@@@@@@@@:                  //
//                  .@*=@@@@@@@@@@@@@#+%@@@@@@@@@@%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@*                  //
//                  *# +@@@@@@@@@@@@@%  :+#@@@@@@@@@@@@@@@%+:.%@@@@@@@@@@@@@@@@@@.                 //
//                 +* .@@@@@@@@@@@@@@@=     :-=+****++=-:     %@@@@@@@@@@@@@@@@@@%:                //
//                +=  #@@@@@@@@@@@@@@@@:                     *@@@@@@@@@@@@@@@@@@@@@*:              //
//              -+.  *@#@@@@@@@@@@@@@@@%.                   *@@@@@@@@@@@@@@@@@@@@@%*@#:            //
//             :.   *%:+@@@@@@@@@@@@@@@@%.                .%#@@@@@@@@@@@@@@@@@@@-@%  =@+           //
//                -#=  %@@@@@@@@@@@@@@@@@%.             :=+.-@@@@@@@@@@@@@@@@@@@:*@=  .*+          //
//                .   =@-@@@@@@@@@@@@@@@@@@:            .   *@@@@@@@@@@@@@@@@@@@* #@.   =          //
//                   .@=.@@@@@@@@@@@@@@@@@@@.               #+*@@@@@@@@@@@@@@@@@@: %#              //
//                   ** :@@@@@@@@@@@@@@@@@@@*               #::@@@@@@@@@@@@@@@@@@%..@=             //
//                  -#  +@@@@@@@@@@@@@@@@@@@@.              +. @@@@@@@@@@@@@@@@@@@%.:%:            //
//                 .#. .@@@@@@@@@@@@@@@@@@@#@=              .- %@@@@@@@@@@@@@@@@@%=#..*.           //
//                .*. -%@@@@@@@@@@@@@@@@@@*-@+                 %@@@@@@@@@@@@@@%#@@*.+=             //
//                  =%@@@@@@@@@@@@@@@@@@@@:=@-                 @@@@@@@@@@@@@@@+ .=%*  -:           //
//              .=#@@#=#@@@@@@@@@@@@@@@@@+ +%                 -@@@@@@@@@@@@@@@@+   :+:             //
//           :+#%*=: .#@@@@@@@@@@@@@*%@@%  #-                 *%.@@@@@@@@@@@%-+%%=   .             //
//        -==-:     =@#-@@@@@@@@@@@@ +@@. .*                  %.:@@@@@@@@@@@%   .=*+=:             //
//               .+%*: +@@@@@@@@@@@% +@:  -                   * +@@@@@@@@@@@@.       :-:           //
//             -*#-    #@@@@@@@@@@@# #-                       . %%.%@@@@@@@@@+                     //
//          -=+-.      *@@@@@@@@@@@* :                         -@: -@@@@@+=@@#                     //
//                     -@@@@*#@@@@@*                          .%:   #@@@@  .%@.                    //
//                      %@@@.:@@@.%%                          -.    .%@@@   :@:                    //
//                      :@@@  #@@ =@.                                :@@@.   *-                    //
//                       :%@-  #@= #*                                 :@@*   =.                    //
//                         :+:  +@= =+                                 .#@+                        //
//                               .+*: .                                  :*%-                      //
//                                  :.                                      :.                     //
//                                                                                                 //
//                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////

/// @title:  Steve Aoki NFT Forge Collection -Level 1 Finale NFT
/// @author:  An NFT powered by Ether Cards - https://ether.cards

import "./ERC721BurnRedeem.sol";
import "./ERC721OwnerEnumerableSingleCreatorExtension.sol";
import "./IERC20.sol";
import "./Strings.sol";
import "./ICreatorExtensionTokenURI.sol";

interface ExtensionInterface {
    function mintNumber(uint256 tokenId) external view returns (uint256);
}

contract Level1FinaleForge is
    ERC721BurnRedeem,
    ERC721OwnerEnumerableSingleCreatorExtension,
    ICreatorExtensionTokenURI
{
    using Strings for uint256;

    address private creator;
    mapping(uint256 => bool) private claimed;
    event forgeWith(
        uint16 _checkToken, // Hop SKip Flop  375
        uint16 _checkToken2, // Xtradit    879
        uint16 _checkToken3, // GameOver   867
        uint16 _checkToken4, // FreshMeat   873
        uint16 _checkToken5, // Vigilant Eye 834
        uint16 _checkToken6, // Bridge Over   801
        uint16 _burnToken  // Distored Reality  123
    );
    event airDropTo(address _receiver);

    string private _endpoint =
        "https://client-metadata.ether.cards/api/aoki/Level1Finale/";

    uint256 public forge_start = 1639674000; // 1639674000 GMT: Thursday, December 16, 2021 5:00:00 PM

    modifier forgeActive() {
        require(block.timestamp >= forge_start, "not started.");
        _;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            ERC721BurnRedeem,
            IERC165,
            ERC721CreatorExtensionApproveTransfer
        )
        returns (bool)
    {
        return
            interfaceId == type(ICreatorExtensionTokenURI).interfaceId ||
            super.supportsInterface(interfaceId) ||
            ERC721CreatorExtensionApproveTransfer.supportsInterface(
                interfaceId
            );
    }

    constructor(
        address _creator, //  0x01Ba93514e5Eb642Ec63E95EF7787b0eDd403ADd
        uint16 redemptionRate, // 1
        uint16 redemptionMax // 10
    )
        ERC721OwnerEnumerableSingleCreatorExtension(_creator)
        ERC721BurnRedeem(_creator, redemptionRate, redemptionMax)
    {
        creator = _creator;
    }

    /* 
    check whether can claim or not , if can claim return true.
    */
    function checkClaim(uint256 _tokenID) public view returns (bool) {
        return (!claimed[_tokenID]); // check status. false by default. then become true after claim.
    }

    function setup() external onlyOwner {
        super._activate();
    }

    function EmergencyAirdrop(address _to) external onlyOwner {
        _mintRedemption(_to);
        emit airDropTo(_to);
    }

    //
    // Hop SKip Flop - 374-383
    // Mainnet
    
address public Xtradit = 0x2b09d7DBab4D4a3a7ca4AafB691bB8289b8c132A;
address public GameOver = 0x0d0dCD1af3D7d4De666F252c9eBEFdBF913fa3eb;
address public FreshMeat = 0xf9a38984244A37d7040d9bbE35aa7dd58C00ed9A;
address public VigilantEye = 0x3383a9C5dB21FE5e00491532CC5f38A1Bd747dcd;
address public BridgeOver = 0x2e631e51F83f5aD99dd69B812D755963633c8b62;
/*
    // Testnet
    address private Xtradit = 0x135A1979777A3c7EA724d850330841664Bd649da;
    address private GameOver = 0xE4Dd95316F3418AdDc17C484f012Dd4d34e7AFbC;
    address private FreshMeat = 0x821Ef6ED46E98bdE236fE6CBF9238d25EaBF9cf9;
    address private VigilantEye = 0xB4829d4E667f5Fe3F5058F8739e3e55F48bD0c49;
    address private BridgeOver = 0xf76c14106feD1e2F35b63B7c59De5143f8a22b2B;
*/
    function forge(
        uint16 _checkToken, // Hop SKip Flop
        uint16 _checkToken2, // Xtradit
        uint16 _checkToken3, // GameOver
        uint16 _checkToken4, // FreshMeat
        uint16 _checkToken5, // Vigilant Eye
        uint16 _checkToken6, // Bridge Over
        uint16 _burnToken //  DistortedReality
    ) external forgeActive() {
        // Attempt Burn
        // Check that we can burn

        require(374 <= _checkToken && _checkToken <= 383, "!H");

        require(ExtensionInterface(Xtradit).mintNumber(_checkToken2) > 0 && ( ExtensionInterface(GameOver).mintNumber(_checkToken3) > 0 ), "!2 & !3");
        require(ExtensionInterface(FreshMeat).mintNumber(_checkToken4) > 0 && ( ExtensionInterface(VigilantEye).mintNumber(_checkToken5) > 0 ), "!4 & !5");
        require(redeemable(creator, _burnToken) && ExtensionInterface(BridgeOver).mintNumber(_checkToken6) > 0 , "IT , !6");

        require(checkClaim(_checkToken) == true && ( IERC721(creator).ownerOf(_checkToken) == msg.sender), "F1");
        require(checkClaim(_checkToken2) == true && ( IERC721(creator).ownerOf(_checkToken2) == msg.sender), "F2");
        require(checkClaim(_checkToken3) == true && (IERC721(creator).ownerOf(_checkToken3) == msg.sender), "F3");
        require(checkClaim(_checkToken4) == true && (IERC721(creator).ownerOf(_checkToken4) == msg.sender) , "F4");
        require(checkClaim(_checkToken5) == true && (IERC721(creator).ownerOf(_checkToken5) == msg.sender), "F5");
        require(checkClaim(_checkToken6) == true &&( IERC721(creator).ownerOf(_checkToken6) == msg.sender), "F6");

        // There is an invent in checkClaim.
        // Restructure setup and to have the same interface.
        claimed[_checkToken] = true;
        claimed[_checkToken2] = true;
        claimed[_checkToken3] = true;
        claimed[_checkToken4] = true;
        claimed[_checkToken5] = true;
        claimed[_checkToken6] = true;

        // Then burn
        try
            IERC721(creator).transferFrom(
                msg.sender,
                address(0xdEaD),
                _burnToken
            )
        {} catch (bytes memory) {
            revert("Bf");
        }

        // Mint reward
        _mintRedemption(msg.sender);
        emit forgeWith(
            _checkToken, // Hop SKip Flop
            _checkToken2, // Xtradit
            _checkToken3, // GameOver
            _checkToken4, // FreshMeat
            _checkToken5, // Vigilant Eye
            _checkToken6, // Bridge Over
            _burnToken
        );
    }

    // tokenURI extension
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_mintNumbers[tokenId] != 0, "It");
        return
            string(
                abi.encodePacked(
                    _endpoint,
                    uint256(int256(_mintNumbers[tokenId])).toString()
                )
            );
    }

    function tokenURI(address _creator, uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return tokenURI(tokenId);
    }


    function drain(IERC20 _token) external onlyOwner {
        if (address(_token) == 0x0000000000000000000000000000000000000000) {
            payable(owner()).transfer(address(this).balance);
        } else {
            _token.transfer(owner(), _token.balanceOf(address(this)));
        }
    }

    function retrieve721(address _tracker, uint256 _id) external onlyOwner {
        IERC721(_tracker).transferFrom(address(this), msg.sender, _id);
    }

        function setTime(uint256 _time) external onlyOwner {
        forge_start = _time;
    }

    function how_long_more()
        public
        view
        returns (
            uint256 Days,
            uint256 Hours,
            uint256 Minutes,
            uint256 Seconds
        )
    {
        require(block.timestamp < forge_start, "Started");
        uint256 gap = forge_start - block.timestamp;
        Days = gap / (24 * 60 * 60);
        gap = gap % (24 * 60 * 60);
        Hours = gap / (60 * 60);
        gap = gap % (60 * 60);
        Minutes = gap / 60;
        Seconds = gap % 60;
        return (Days, Hours, Minutes, Seconds);
    }
}
