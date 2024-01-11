// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

/*
    ,---,.                                  ____
    ,'  .'  \                               ,'  , `.
    ,---.' .' |    ,---.      ,---.        ,-+-,.' _ |
    |   |  |: |   '   ,'\    '   ,'\    ,-+-. ;   , ||
    :   :  :  /  /   /   |  /   /   |  ,--.'|'   |  ||
    :   |    ;  .   ; ,. : .   ; ,. : |   |  ,', |  |,
    |   :     \ '   | |: : '   | |: : |   | /  | |--'
    |   |   . | '   | .; : '   | .; : |   : |  | ,
    '   :  '; | |   :    | |   :    | |   : |  |/
    |   |  | ;   \   \  /   \   \  /  |   | |`-'
    |   :   /     `----'     `----'   |   ;/
    |   | ,'                          '---'
    `----'
*/

contract Boom is ERC721, ERC721Enumerable, Ownable {
    using ECDSA for bytes32;

    string private _baseTokenURI;
    address private _signer;
    string private _contractURI;

    uint256 public constant MAX_SUPPLY = 500;
    bool public publicClaim = false;

    constructor(
        address signer,
        string memory _initialBaseURI,
        string memory _initialContractURI
    ) ERC721("Boom Pinoeer Card", "BPC") {
        _signer = signer;
        _baseTokenURI = _initialBaseURI;
        _contractURI = _initialContractURI;
    }

    function claim(uint256 tokenId, bytes memory signature) external {
        require(publicClaim, "Boom: claim is not active.");
        require(
            tx.origin == msg.sender,
            "Boom: contract is not allowed to claim."
        );
        require(
            _verify(msg.sender, tokenId, signature),
            "Boom: invalid signature."
        );
        require(totalSupply() + 1 <= MAX_SUPPLY, "Boom: Max supply exceeded.");
        _safeMint(msg.sender, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // View Contract-level URI
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // Set Contract-level URI
    function setContractURI(string memory contractURI_) external onlyOwner {
        _contractURI = contractURI_;
    }

    function setSigner(address signer) external onlyOwner {
        _signer = signer;
    }

    function flipClaimState() external onlyOwner {
        publicClaim = !publicClaim;
    }

    function _verify(
        address _sender,
        uint256 _tokenId,
        bytes memory _signature
    ) internal view returns (bool) {
        return
            keccak256(abi.encodePacked(_sender, _tokenId))
                .toEthSignedMessageHash()
                .recover(_signature) == _signer;
    }
}
