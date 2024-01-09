// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./ERC721.sol";
import "./Mintable.sol";

contract Asset is ERC721, Mintable {

    string  private _defaultURI;
    uint256 private _supply;
    uint256 private _imx_supply;
    uint256 public maxSupply = 555;

    event ImxMint(uint256 value);

    constructor(
        address _owner,
        string memory _name,
        string memory _symbol,
        address _imx
    ) ERC721(_name, _symbol) Mintable(_owner, _imx) {
        setDefaultURI("https://api.cryptomaids.tokyo/metadata/butler/");
    }

    function _mintFor(
        address user,
        uint256 id,
        bytes memory
    ) internal override {
        _safeMint(user, id);
        _supply++;
    }

    function setDefaultURI(string memory defaultURI_) public onlyOwner {
        _defaultURI = defaultURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return _defaultURI;
    }

    // minting is handled off-chain using Immutable X client API. 
    // invalid transactions (insufficient value, invalid sale date, unauthorized whitelist...etc) will be ignored.
    function mintButler() public payable {
        emit ImxMint(msg.value);
    }

    function withdraw(address payable recipient, uint256 amount) public onlyOwner {
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Failed to withdraw Ether");
    }

    function totalSupply() public view virtual returns (uint256) { return _supply; }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}