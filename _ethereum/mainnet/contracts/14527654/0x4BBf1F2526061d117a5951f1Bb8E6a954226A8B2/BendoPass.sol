// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155Supply.sol";
import "./ERC1155.sol";
import "./Address.sol";
import "./Strings.sol";
import "./Pausable.sol";
import "./Whitelist.sol";

contract BendoPass is ERC1155, ERC1155Supply, Whitelist, Pausable {
    using Address for address;

    uint public immutable MAX_SUPPLY = 500;
    uint8 public immutable ID_BENDO_PASS = 1;

    uint public maxMint = 2;
    uint public price = 0.08 ether;

    string public name = "Bendo Pass";
    string public symbol = "MuraPass";

    address public murasaiContract;

    mapping(address => mapping(uint => bool)) public bendoBurned;

    constructor(string memory _uri) ERC1155(_uri) {
        _pause();
    }

    function mintBendo(uint8 amount) public whenNotPaused payable {
        require(whitelist[msg.sender], "you are not in the whitelist");
        require(amount > 0, 'you must mint more than 0');
        require(msg.value >= price * amount, 'value below price');
        require(balanceOf(msg.sender, ID_BENDO_PASS) + amount <= maxMint, 'you can not mint more than maxMint');
        require(totalSupply(ID_BENDO_PASS) <= MAX_SUPPLY, 'you can not mint more merch B');
        _mint(msg.sender, ID_BENDO_PASS, amount, "");
    }

    function uri(uint256 _id) public view override returns (string memory) {
        require(exists(_id), "URI: nonexistent token");
        return string(abi.encodePacked(super.uri(_id), Strings.toString(_id)));
    }

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() ||
            isApprovedForAll(account, _msgSender()) ||
            _msgSender().isContract() && Ownable(_msgSender()).owner() == owner()
            ,
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, value);
        bendoBurned[account][id] = true;
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() ||
            isApprovedForAll(account, _msgSender()) ||
            _msgSender().isContract() && Ownable(_msgSender()).owner() == owner(),
            "ERC1155: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
        for(uint i=0; i < ids.length; i++) {
            uint id = ids[i];
            bendoBurned[account][id] = true;
        }
    }

    function setURI(string memory baseURI) external onlyOwner {
        _setURI(baseURI);
    }

    function setPrice(uint _price) public onlyOwner {
        price = _price;
    }

    function setMurasaiContract(address _murasaiContract) public onlyOwner {
        require(_murasaiContract.isContract(), "it's not a contract");
        murasaiContract = _murasaiContract;
    }

    function withdrawPercent(uint16 percent) public onlyOwner {
        require(address(this).balance > 0, "no ETH");
        require(percent > 0, "the percentage must be greater than 0");
        uint amount = address(this).balance * percent / 100;
        payable(owner()).transfer(amount);
    }

    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "no ETH");
        payable(owner()).transfer(address(this).balance);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    fallback() external payable {}
    receive() external payable {}
}
