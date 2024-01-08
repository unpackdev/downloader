// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./ERC1155Holder.sol";
import "./Ownable.sol";

contract BloodyFacesMintPass is ERC1155, Ownable, ERC1155Holder {
    bool public isMinted = false;
    uint public totalSupply = 3333;
    mapping(address => uint8) private _buyers;
    
    constructor() ERC1155("https://bloodyfaces.io/api/mintpass/{id}") {}

    function mintAllPasses() public onlyOwner {
        require(!isMinted, "Bloody Faces are already minted.");

        _mint(address(this), 0, totalSupply, "");
        isMinted = true;
    }

    function buyPass(uint256 _amount) public payable {
        require(_amount <= 3, "Maximum quantity is 3.");
        require(_amount > 0, "Minimum quantity is 1.");
        require(_buyers[msg.sender] + _amount <= 3, "Cannot buy more than 3 Bloody Faces pass.");
        require(balanceOf(address(this), 0) >= _amount, "Not enough Bloody Faces left.");
        require(msg.value == 0.03 ether * _amount, "Price is 0.03 eth.");

        this.safeTransferFrom(address(this), msg.sender, 0, _amount, "");
        for (uint8 i = 0; i < _amount; i++) {
            _buyers[msg.sender]++;
        }
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /*
    * @return Returns contract metadata used by OpenSea
    */
    function contractURI() public pure returns (string memory) {
        return "https://bloodyfaces.io/api/metadata";
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC1155Receiver) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
