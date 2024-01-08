//SPDX-License-Identifier: Unlicensed
pragma solidity 0.7.3;

import "./ERC721.sol";
import "./ERC20.sol";
import "./controllerPanel.sol";

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
contract ClaimTokenContract is controllerPanel {
    IERC721Enumerable public giveAwayToken;
    IERC721Enumerable public checkToken;
    mapping(uint256 => bool) private canClaim;
    address public vault;
    uint256 public claimCount = 0;

    modifier claimActive() {
        require(block.timestamp >= claim_start, "Claim not started.");
        _;
    }
    uint256  public claim_start =  1630515600; // 1am
    uint256[] public claimArray = [
        537, // Worlds Collide
        872,// Getting Jacked
        870,
        854,
        849,
        848,
        832,
        829,
        822,
        802,
        811,
        797,
        794,// Getting Jacked
        701,// Finding Serenity
        700,
        698,
        692,
        691,
        683,
        673,
        670,
        675,
        667,
        663,
        662,
        660,
        659,
        632,// Finding Serenity
        605,// It Came From Above:
        599,
        596,
        591,
        578,
        575,// It Came From Above:
        768, // Fighting Gravity
        765, 
        762,
        761,
        759,
        741,
        727,
        710 // Fighting Gravity
    ];

    constructor() {
        giveAwayToken = IERC721Enumerable(0x01Ba93514e5Eb642Ec63E95EF7787b0eDd403ADd);
        checkToken = IERC721Enumerable(0xdDA2eA1cef44c206818161E7876f7277Bd39a99c);
        vault = address(0x6a43A7dfab20E547c2DcFAA2Ac43BBB02fCFbfA0);
    }

    function checkClaim(uint256 _tokenID) public view returns (bool) {
        return (canClaim[_tokenID]);
    }

    function checkNext() internal view returns (uint256) {
        return (claimArray[claimArray.length - 1]);
    }

    function getTokenID(uint256 _claimID) public view returns (uint256) {
        return claimArray[_claimID];
    }

    function claim(uint256 _tokenID) external claimActive {
        require(checkToken.ownerOf(_tokenID) == msg.sender, "Not token Owner");
        require(canClaim[_tokenID] == true, "Claimed");
        uint256 bal = giveAwayToken.balanceOf(vault);
        require(bal > 0, "No more tokens to claim.");
        uint256 _tokenId = checkNext();
        canClaim[_tokenID] = false;
        claimArray.pop();
        claimCount++;
        giveAwayToken.transferFrom(vault, msg.sender, _tokenId);

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
        require(block.timestamp < claim_start, "Started");
        uint256 gap = claim_start - block.timestamp;
        Days = gap / (24 * 60 * 60);
        gap = gap % (24 * 60 * 60);
        Hours = gap / (60 * 60);
        gap = gap % (60 * 60);
        Minutes = gap / 60;
        Seconds = gap % 60;
        return (Days, Hours, Minutes, Seconds);
    }

    function setup() external onlyAllowed {
        canClaim[5200010001] = true;

        uint256 baseFormat = 5200030000;
        for (uint256 i = 1; i <= 10; i++) {
            canClaim[baseFormat + i] = true;
        }

        baseFormat = 5200040000;
        for (uint256 i = 1; i <= 15; i++) {
            canClaim[baseFormat + i] = true;
        }
        baseFormat = 5200060000;
        for (uint256 i = 1; i <= 35; i++) {
            canClaim[baseFormat + i] = true;
        }

        baseFormat = 5200070000;
        for (uint256 i = 1; i <= 50; i++) {
            canClaim[baseFormat + i] = true;
        }
        baseFormat = 5200080000;
        for (uint256 i = 1; i <= 80; i++) {
            canClaim[baseFormat + i] = true;
        }
    }

    function EmergencySet(uint256 _ID) external onlyAllowed {
        canClaim[_ID] = true;
    }

    function EmergencyPush(uint256 _ID) external onlyAllowed {
        claimArray.push(_ID); // Push to the back.
    }
    // Pull out
    receive() external payable {
        // React to receiving ether
    }

    function drain(IERC20 _token) external onlyAllowed {
        if (address(_token) == 0x0000000000000000000000000000000000000000) {
            payable(owner()).transfer(address(this).balance);
        } else {
            _token.transfer(owner(), _token.balanceOf(address(this)));
        }
    }

    function retrieve721(address _tracker, uint256 _id) external onlyAllowed {
        IERC721(_tracker).transferFrom(address(this), msg.sender, _id);
    }
}
