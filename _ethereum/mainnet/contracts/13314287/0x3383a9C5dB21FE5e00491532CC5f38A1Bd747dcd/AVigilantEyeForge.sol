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

/// @title:  Steve Aoki NFT Forge Collection - A Vigilant Eye
/// @author:  An NFT powered by Ether Cards - https://ether.cards


import "./ERC721BurnRedeem.sol";
import "./ERC721OwnerEnumerableSingleCreatorExtension.sol";
import "./IERC20.sol";
import "./Strings.sol";
import "./ICreatorExtensionTokenURI.sol";

contract AVigilantEyeForge is
    ERC721BurnRedeem,
    ERC721OwnerEnumerableSingleCreatorExtension,
    ICreatorExtensionTokenURI
{
    using Strings for uint256;

    address public creator;
    mapping(uint256 => bool) private claimed;
    event forgeWith(uint16 _checkToken, uint16 _checkToken2, uint16 _burnToken);
    event airDropTo(address _receiver);

    string private _endpoint =
        "https://client-metadata.ether.cards/api/aoki/AVigilantEye/";

    uint256 public forge_start = 1632931200; // 9am PST 29/9/2021

    string public surprise = "https://youtu.be/402OrPvfYlU?t=2575";

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
        uint16 redemptionMax // 83
    )
        ERC721OwnerEnumerableSingleCreatorExtension(_creator)
        ERC721BurnRedeem(_creator, redemptionRate, redemptionMax)
    {
        creator = _creator;
    }
    /* 
    check whether can claim or not , if can claim return true.
    */ 
    function checkClaim(uint256 _tokenID) public view returns (bool) { //
        bool checkRange = (625 <= _tokenID && _tokenID <= 707) || (791 <= _tokenID && _tokenID <= 873);
        if (!checkRange) { // not in range. 
            return false;
        }  else {
        return (!claimed[_tokenID]);  // check status. false by default. then become true after claim. 
        }
    }

    function setup() external onlyOwner {
        super._activate();
    }

    function EmergencyAirdrop(address _to) external onlyOwner {
        _mintRedemption(_to);
        emit airDropTo(_to);

    }
    
    function forge(
        uint16 _checkToken, // FindingSerenity 
        uint16 _checkToken2, // GettingJacked
        uint16 _burnToken //  DistortedReality
    ) public forgeActive() {
        // Attempt Burn
        // Check that we can burn
        require(625 <= _checkToken && _checkToken <= 707, "!S");
        require(791 <= _checkToken2 && _checkToken2 <= 873, "J");

        require(redeemable(creator, _burnToken), "IT");
        require(checkClaim(_checkToken) == true, "F1");
        require(checkClaim(_checkToken2) == true, "F2");
        // There is an invent in checkClaim. 
        // Restructure setup and to have the same interface. 
        claimed[_checkToken] = true;
        claimed[_checkToken2] = true;

        require(IERC721(creator).ownerOf(_checkToken) == msg.sender, "own1");
        require(IERC721(creator).ownerOf(_checkToken2) == msg.sender, "own2");
        require(IERC721(creator).ownerOf(_burnToken) == msg.sender, "own3");
        require(IERC721(creator).getApproved(_burnToken) == address(this), "approval");

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
        emit forgeWith(_checkToken, _checkToken2, _burnToken);
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

    function tokenURI(address creator, uint256 tokenId)
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
