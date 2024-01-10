// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*

 :P&@@@@@@&BY^                                   .?5?                                           .^!!!^.                                               
 @@@@@@@@@@@@@@P.                  .B&&G.        &@@@&            J##P:                     :Y#@@@@@@@@&G!                       ..                   
.@@@@@Y!?YG@@@@@@!                 ~@@@@#        ?@@@@G          .@@@@@~                  ~#@@@@@@&&@@@@@@&~                   ^&@@B                  
:@@@@@    !#@@@@@5                  Y@@@@?        #@@@@:          .@@@@&                 P@@@@@&7.   ^&@@@@@.                  P@@@@                  
^@@@@@&@@@@@@@@@@7                   &@@@@        :@@@@B           5@@@@^               #@@@@@Y        JGBG!    .^~^:          #@@@& .:!~.  :JG#&#GJ: 
~@@@@@@@@@@@@@@@@@@G^                ?@@@@?        #@@@@.          J@@@@~              P@@@@@J               .5&@@@@@@#PY.  :~?@@@@@@@@@@@.P@@@@&@@@@G
7@@@@@5J????J5B&@@@@@G   :5GY.  :77: .@@@@&7?~:    J@@@@#GGJ^      P@@@@:   ^JGBBGJ.  :@@@@@#               7@@@@@B#@@@@@B~@@@@@@@@@@@&#G~ @@@@:   B#J
?@@@@&          ~&@@@@# .@@@@B  @@@@! &@@@@@@@@&5. ^@@@@@@@@@@J    &@@@@  7&@@@@@@@@? ?@@@@@7              :@@@@P  P@@@@@#:#&&#@@@@J       :&@@@#Y^   
Y@@@@#            @@@@@7.@@@@B .&@@@@ B@@@@#G&@@@@::@@@@@5P&@@@#  :@@@@G G@@@@&  @@@& ?@@@@@7              ~@@@@JY@@@@@@@&    :@@@@!         !P&@@@@G.
P@@@@B           .@@@@@7 &@@@@. P@@@@^B@@@@   P@@@#^@@@@Y   @@@@! P@@@@^7@@@@@@@@@@&: .@@@@@&               5@@@@@@@@B@@@@7   .@@@@7     .@@@   .Y@@@#
G@@@@G         .J@@@@@B  !@@@@@B@@@@&.&@@@@   G@@@G!@@@@J  :@@@@: @@@@& 7@@@@@      .: !@@@@@&^          ^?Y?7JGBB5~  G@@@&    @@@@G      7@@@@&&@@@@7
G@@@@&Y?777?YG&@@@@@@Y    ^B@@@@@@@B. &@@@@&B&@@@&.!@@@@@B#@@@@Y ?@@@@?  5@@@@@@@@@@@@. ^&@@@@@&P?!!7JP#@@@@@@.        !YJ.    P@@@@?       !P#&&#G7. 
Y@@@@@@@@@@@@@@@@@&J.       .^!??~.   :Y#@@@@@@#?   J#@@@@@@@G:  #@@@@.   .Y#&@@&&#B5^    !#@@@@@@@@@@@@@@@&P~                  B@@@@:                
 :JP#&@@@@@@@&B5!.                       .^~~:        .~?J?^     !&@&7                      .~JG#&&&&&#PJ~.                      :77.                 


    Author: exarch.eth
*/

import "./ERC1155.sol";
import "./ReentrancyGuard.sol";

contract BubbleCats is ERC1155, ReentrancyGuard {
    string public constant name = "BubbleCats";
    string public constant symbol = "BUBBLE";
    uint256 public constant maxSupply = 303;

    address private _owner;
    string private _baseURI;
    uint256 private _totalSupply;

    constructor() {
        _owner = msg.sender;
    }

    //======================== MODIFIERS ========================

    modifier isOwner() {
        require(_owner == msg.sender, "NOT_OWNER");
        _;
    }

    modifier checkMaxSupply(uint256 num) {
        require(_totalSupply + num <= maxSupply, "MAX_SUPPLY");
        _;
    }

    modifier tokenExists(uint256 tokenId) {
        require(tokenId > 0 && tokenId <= _totalSupply, "NULL_TOKEN");
        _;
    }

    //==================== EXTERNAL FUNCTIONS ====================

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function owner() external view returns (address) {
        return _owner;
    }

    function setOwner(address newOwner) external payable isOwner {
        _owner = newOwner;
    }

    function emergencyWithdraw(address payable to) external payable isOwner {
        to.transfer(address(this).balance);
    }

    function blowBubbles(
        string calldata newURI,
        address to,
        uint256 amount,
        bytes calldata data
    ) external payable isOwner checkMaxSupply(amount) nonReentrant {
        require(amount > 0, "ZERO_AMOUNT");

        setBaseURI(newURI);

        for (uint256 i = 0; i < amount; ) {
            unchecked {
                ++i;
                ++_totalSupply;
            }

            _mint(to, _totalSupply, 1, data);
        }
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        tokenExists(_tokenId)
        returns (address receiver, uint256 royaltyAmount)
    {
        return (address(_owner), (_salePrice * 5) / 100);
    }

    //===================== PUBLIC FUNCTIONS =====================

    function uri(uint256 id)
        public
        view
        override
        tokenExists(id)
        returns (string memory)
    {
        return string(abi.encodePacked(_baseURI, uint2str(id)));
    }

    function setBaseURI(string calldata newURI) public payable isOwner {
        _baseURI = newURI;
        emit URI(newURI, 0);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override
        returns (bool)
    {
        return
            interfaceId == 0x2a55205a || super.supportsInterface(interfaceId);
    }

    //==================== INTERNAL FUNCTIONS ====================

    function uint2str(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
