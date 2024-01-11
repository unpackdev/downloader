// SPDX-License-Identifier: MIT

// Artwork-License-Identifier: CC0

/*

b̶̨͖̟͙̳̖͉̠͔̗̰̥̟̞̮̌̅l̵͓̝̱̞̈́̀͊͊͑̾͑̈́͘̕a̶͇̋̿̏̋̎͆̈́̓̊̇̈́̅̔͘͝ṟ̴̣̳͉̯͇͎͗̈͐͛̓̓͒͋͘͘͝ͅg̴̪̞̗̪͋̓͗͊̿̅́̄̎̓ ̷̛̛̞͇̦̔̌̔́͆̒͊͑̓̾̐̕̕̕͠i̶̢̥̦̲̗͉͙͚̭̐̒͘͜s̷̢̧̭̝̮͎͐̑̈̋͝ ̸̻̹̗̏̈́͑͆̔̔͘͝ͅo̴̢̱̣̮̖̟̻̭̍̈́̇̔͋͝n̶͈̬͙̰̤̘̭̰͍̪͚̟͈̗͓͙͑ͅé̵̙͎̖̙̹͈͍̗́̕͝͝͝,̴̢̣̳̬̦̱̣̠̠̟͇̙͖̏̈͛̿̿ͅ ̶͖͇̝̦͇̤͍̗̫͖͎̥͌̐̀̃͆b̵̛͔̬̝̗̩͍̲̈̄̒̌̊̔̄̃̌̌̽̅̋͘͜͠l̷̡̬̗͎̻͖͉͚̥̪̞͙̖̰̟̊̋̋̆͊ͅą̵̧̧̛̼͙̩̰̖̲̳̠̫̩͇̀̇̒͜r̷̡̘̠̠̟̈ģ̶̺̳̻̯̈́͒͆͂̀́̊̆̈́̿ͅ ̵̢̬̖͎̣̻̼̝̪̪̣̈́́̿̆̒̀͝͝į̵̧̛̞͚̜͇̺͔̟̼͉͙̲̒̒̔̈́̒͐̂̂̕͝ͅṡ̴̪͕̿ ̴̡̛̲̰̬͎͖̖̰̝̲̰̮͚̞̩̮̍̏͑̒̏̕̚͝ạ̶̢͈̻̫͐̓̇͗̾̕l̸̳̤͖͔̯̱̖̺͚̞̰̮͍͈̯̐̐̄͌̃̓̃̍̀̊͘͠l̶̖̟̼͇̫͕͈͓̹̞͋̒̍̇̓̀̓̅̏͒͑̊̕.̵͍͔̬͚̜͙̓̃̅̈́͝

*/

pragma solidity ^0.8.11;
import "./ERC721A.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}


contract BlargNFT is ERC721A, Ownable {

    using ECDSA for bytes32;

    uint256 public BUY_PRICE = 0.01 * 1 ether;

    uint256 public RESERVE_TOKENS = 37;

    uint256 public maxSupply = 1337;

    string public baseURI;
    string public contractURI;

    address[3] private shareholders = [
        0x7902DC17644cB68fc421D3889e77BdD8125fdDb0,
        0x1593d55A7ffbc63Cc9Ff47EBF13b4475fdBb4c66,
        0x44f6498D1403321890F3f2917E00F22dBDE3577a
    ];

    constructor() ERC721A("Blarg", "BLARG") {
        _safeMint(address(this), 1);
        _burn(0);
    }

    function reserveTeamTokens(
        uint256 amount
    ) external onlyOwner {
        require(_numberMinted(msg.sender) + amount <= RESERVE_TOKENS, "BLARG//RESERVE_LIMIT_REACHED");
        _safeMint(msg.sender, amount);
    }

    function mint() external {
        require(msg.sender == tx.origin, "BLARG//ONLY_EOA");
        require(_numberMinted(msg.sender) == 0, "BLARG//ALREADY_MINTED");
        require(totalSupply() + 1 <= maxSupply, "BLARG//SOLD_OUT");
        _safeMint(msg.sender, 1);
    }

    function buy() external payable {
        require(msg.sender == tx.origin, "BLARG//ONLY_EOA");
        require(_numberMinted(msg.sender) == 1, "BLARG//MINT_FREE_FIRST");
        require(msg.value == 0.01 * 1 ether, "BLARG//INSUFFICIENT_FUNDS");
        require(totalSupply() + 1 <= maxSupply, "BLARG//SOLD_OUT");
        _safeMint(msg.sender, 1);
    }

    function hasMinted() view external returns (uint256) {
        return _numberMinted(msg.sender);
    }

    function setBaseURI(
        string memory _uri
    ) external onlyOwner {
        baseURI = _uri;
    }

    function setContractURI(
        string memory _uri
    ) external onlyOwner {
        contractURI = _uri;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(shareholders[0]).transfer(balance * 33 / 100);
        payable(shareholders[1]).transfer(balance * 33 / 100);
        payable(shareholders[2]).transfer(address(this).balance);
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
        return string(abi.encodePacked(baseURI, uint2str(id)));
    }

}