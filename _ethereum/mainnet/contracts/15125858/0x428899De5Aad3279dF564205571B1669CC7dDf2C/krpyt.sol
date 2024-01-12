// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.15;

import "./ERC721A.sol";
import "./Ownable.sol";

interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}

contract pordi is ERC721A, Ownable {

    uint256 public BUY_PRICE = 0.02175 * 1 ether;

    uint256 public maxSupply = 3102;

    uint256 public REVEAL_BLOCK;

    string public baseURL;
    string public _contractURI;

    constructor() ERC721A(unicode"Портал", unicode"Портал") {
        _safeMint(address(this), 3);
        _burn(0);
        REVEAL_BLOCK = block.number + (5500 * 7);
    }

    function mint() external {
        require(msg.sender == tx.origin, unicode"Портал|BAD_ORIGIN");
        require(totalSupply() + 1 <= maxSupply, unicode"Портал|SOLD_OUT");
        require(_numberMinted(msg.sender) == 0, unicode"Портал|ALREADY_MINTED");
        _safeMint(msg.sender, 1);
    }

    function buy() external payable {
        require(msg.sender == tx.origin, unicode"Портал|BAD_ORIGIN");
        require(totalSupply() + 1 <= maxSupply, unicode"Портал|SOLD_OUT");
        require(_numberMinted(msg.sender) == 1, unicode"Портал|MINT_FREE");
        require(msg.value == BUY_PRICE * 1 ether, unicode"Портал|INSUFFICIENT");
        _safeMint(msg.sender, 1);
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function mintCount() view external returns (uint256) {
        return _numberMinted(msg.sender);
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function tokenURI(
        uint256 id
    ) public view override returns (string memory) {
        return block.number >= REVEAL_BLOCK ? string(abi.encodePacked(baseURL, uint2str(id))) : "https://gateway.pinata.cloud/ipfs/QmTePLRK2Z5YeeCXfUzMQ2uubLpTbRcjsRtjGX4rx7xajD";
    }

    function contractURI() public pure returns (string memory) {
        return "https://gateway.pinata.cloud/ipfs/QmbR6YfAXBSreoDhhpiZhLB6yaRhnjKQnzhiDShGrDEV2r";
    }

    function setBaseURI(
        string memory _uri
    ) external onlyOwner {
        baseURL = _uri;
    }

    function setContractURI(
        string memory _uri
    ) external onlyOwner {
        _contractURI = _uri;
    }

}

/*

п̸̜̯̟͗̌о̸̥̰̻͕̝͕̤̗͓̙͐͋̑͂͊р̵̢̡̗͕̝̖̙̱̮͕̤̮̐ͅт̷̢̡͕͙͍̣͆͋̄̈́̑̀̈́͗̀̐̒͛̀͝͠а̷̭̀̿͛̆̅͑̀̑̂͘̚л̵̲̲̝̝̺̰̰͓̯̞̖̻́̅͜͝ ̴̛̘̭͕̫̲̤̎̏̅̂͐̀̽͛͑̊͋͑̐̚͜о̵̛̠̟̖̖̞̓̓́̿͐̉͆͛̈̾̆ͅͅт̷̨̢̛̝̪̼̣̮̪̪͈͌̍̇̔͒̐̉̕͝к̶̢̡̯̜͉͔̟̉̆̉̈͋͌͂̊͛̅͂̈͆͜ͅͅр̵̣͉̜̪̝͇͎̜͍͇̭̱̮̈́̀̀̚ͅͅо̵̹̻͔̭͍̻͍̥̻͙̓͒͑̓͊̊̀̀̀̊͌͘̕͠е̸̢̩̟̹̙̫̟̗̖͑͒̓͂̂͛̑͑̋̎͐̀͒͝͠т̷͈̞̦̪̟͕̩͎̞̝̫̬͂̈́̉͛с̶̬̼͚͂̐͊̃̒͛̓̉͂̄͝я̸̗̌ ̶̼̘̝̦͒͂ͅ1̴̡̭̟̩̳̼̥̖̗̹͙̠̅̊̆͋̒̊͂̑̀͛́͒̕͘͝8̶̢͉̯͈͓̤̥̪̠͚̰͚̝̆͑̇͑̎̉͝ ̷̩̗͓͓͇̘̔͂̓ѝ̴̧͇̗̏̈́̐͑̾͛̾͆͝͝ю̴̢̢̧̛̲̬̼̦̭͓̳͔̺̖́̂̊͊́̉л̷̲͎͓̞̒я̸̹͙̝̓̑̏ ̸̢̢̡̬͓͉̠̞͖͍̤̠̹͈̻̓̎͐͆̉͋̈́̂̃͋̍̇̚2̴̹͐̓̊̓̿́͊0̶̦̯̘̳̲̣̃̊͝2̴̱̣͇̼̳͙́͊̋́̉̃2̴͈̣̬̣̜͇̪̱̝̱͙̙͓̐ͅ ̴̡͔̙̬̙̠̤͓̫͓̇͐͂͑̓̄͊͑̓͠͠г̴̣̺̖̖̰̻̻̻̰̪͖̲̭̺̄̔̊̕͜.̷͔͓̯̖̱͍̼̲̳͈͉͊̀͑͗̽̇̇̌̚̚͜

*/