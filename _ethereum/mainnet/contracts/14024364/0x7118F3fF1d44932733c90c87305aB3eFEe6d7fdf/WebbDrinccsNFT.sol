// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC1155.sol";
import "./Strings.sol";

contract WebbDrinccsNFT is ERC1155, Ownable, Pausable {

    uint256 private constant _MAX_SUPPLY = 4200;
    uint256 private constant _MAX_PER_TX = 20;
    string public PROVENANCE;

    // Metadata
    uint256 private _counter;

    // Price
    uint256 public price;
    address payable public receiver;

    constructor(
        string memory _tokenURI,
        address payable _receiver,
        string memory _provenance
    ) ERC1155(_tokenURI) {
        receiver = _receiver;
        price = 0.01 ether;
        PROVENANCE = _provenance;
        _counter = 0;
        _pause();
    }

    function setPause(bool pause) external onlyOwner {
        if (pause) {
            _pause();
        } else {
            _unpause();
        }
    }

    function mint(uint256 amount) external payable whenNotPaused {
        require(amount < _MAX_PER_TX + 1, "amount can't exceed 10");
        require(amount > 0, "amount too little");
        require(msg.value >= price * amount, "insufficient fund");
        require(_counter + amount < _MAX_SUPPLY, "no more left to mint");

        _mintBatch(msg.sender, amount);
    }

    function airdrop(address[] calldata target, uint256[] calldata amount) external onlyOwner {
        require(target.length > 0, "no target");
        require(amount.length > 0, "no amount");
        require(target.length == amount.length, "amount and target mismatch");
        uint256 totalAmount = 0;
        for (uint256 i; i < amount.length; i++) {
            totalAmount += amount[i];
        }
        require(_counter + totalAmount < _MAX_SUPPLY, "no more left to mint");
        for (uint256 i; i < target.length; i++) {
            _mintBatch(target[i], amount[i]);
        }
    }

    // Minting fee
    function setPrice(uint256 amount) external onlyOwner {
        price = amount;
    }

    function setReceiver(address payable _receiver) external onlyOwner {
        receiver = _receiver;
    }

    function claim() external {
        require(receiver == msg.sender, "invalid receiver");
        receiver.transfer(address(this).balance);
    }

    // Metadata
    function setTokenURI(string calldata _uri) external onlyOwner {
        _setURI(_uri);
    }

    function totalSupply() external view returns (uint256) {
        return _counter;
    }

    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
        return
            string(
                abi.encodePacked(super.uri(_tokenId), "/", Strings.toString(_tokenId), ".json")
            );
    }

    function _mintBatch(address to, uint256 amount) private {
        uint256[] memory ids = new uint256[](amount);
        uint256[] memory amounts = new uint256[](amount);
        uint256 c = 0;
        for (uint256 i = _counter; i < _counter + amount; i++) {
            ids[c] = i + 1; // token starts from 1
            amounts[c] = 1;
            c++;
        }
        _counter += amount;
        _mintBatch(to, ids, amounts, "");
    }
}
