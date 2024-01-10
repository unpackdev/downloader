pragma solidity ^0.8.0;

import "./MerkleProof.sol";
import "./Ownable.sol";
import "./ERC20Burnable.sol";
import "./ERC721Enumerable.sol";

contract apemferscomic is ERC721Enumerable, Ownable {
    string public baseURI;
    address public jungle;
    address public withdrawAddress;

    bool public publicSaleState = false;
    uint256 public MAX_SUPPLY = 8889;
    bytes32 public proofMerkleRoot = 0x0;

    mapping(address => bool) public projectProxy;
    mapping(uint16 => bool) public apeMfersClaimed;

    uint256 private price = 888 ether;

    constructor(string memory _baseURI, address _withdrawAddress)
        ERC721("ape mfer comic", "apemfercomic")
    {
        baseURI = _baseURI;
        withdrawAddress = _withdrawAddress;
    }

    function setJungleAddress(address _jungle ) public onlyOwner {
        jungle = _jungle;
        return;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function flipProxyState(address proxyAddress) public onlyOwner {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    function togglePublicSale() external onlyOwner {
        publicSaleState = true;
    }

    function setmRoot(bytes32 _root)
        external
        onlyOwner
    {
        proofMerkleRoot = _root;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    function publicMint( uint16 apeMferId, bytes32 l_s , bytes32[] calldata proof) public payable {
        require(apeMfersClaimed[apeMferId] == false, "ape mfer already claimed"); 
        require(publicSaleState == true, "public sale not started");
        // require proof to exist in merkle root
        require(
            MerkleProof.verify(proof, proofMerkleRoot, l_s),
            "wrong proof"
        );
		ERC20Burnable(jungle).burnFrom(msg.sender, price);
        uint256 totalSupply = _owners.length;
        require(totalSupply + 1 < MAX_SUPPLY, "Exceeds max supply.");

        _mint(_msgSender(), totalSupply);
        apeMfersClaimed[apeMferId] = true;
    }

    function burn(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Not approved to burn."
        );
        _burn(tokenId);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = withdrawAddress.call{value: address(this).balance}(
            ""
        );
        require(success, "Failed to send to apetoshi.");
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) return new uint256[](0);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function batchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIds
    ) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            transferFrom(_from, _to, _tokenIds[i]);
        }
    }

    function batchSafeTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIds,
        bytes memory data_
    ) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            safeTransferFrom(_from, _to, _tokenIds[i], data_);
        }
    }

    function isOwnerOf(address account, uint256[] calldata _tokenIds)
        external
        view
        returns (bool)
    {
        for (uint256 i; i < _tokenIds.length; ++i) {
            if (_owners[_tokenIds[i]] != account) return false;
        }

        return true;
    }

    function _mint(address to, uint256 tokenId) internal virtual override {
        _owners.push(to);
        emit Transfer(address(0), to, tokenId);
    }

    function setMintPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }
}

contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
