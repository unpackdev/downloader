// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./Ownable.sol";
import "./Address.sol";
import "./ERC721Enumerable.sol";
import "./ApeDadsJuice.sol";

contract MutantApeDads is ERC721Enumerable, Ownable {
    string  public              baseURI;
    address public              proxyRegistryAddress;
    uint256 public              MAX_SUPPLY;
    address public              apeDadsContract;
    address public              apeDadsSerumContract;

    mapping(uint256 => bool) public mutantApeDadsClaimed; // holds apedads nft ids
    uint256[] private claimedIds;
    mapping(address => bool) public projectProxy;

    event MutantApeDadsClaimed(uint256 apeDadsId);

    constructor(
        string memory _baseURI,
        address _proxyRegistryAddress,
        address _apeDadsContract,
        address _apeDadsSerumContract
    )
    ERC721("Future ApeDads", "FUTDAD")
    {
        baseURI = _baseURI;
        proxyRegistryAddress = _proxyRegistryAddress;
        apeDadsContract = _apeDadsContract;
        apeDadsSerumContract = _apeDadsSerumContract;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function toggleProxyState(address proxyAddress) public onlyOwner {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    function togglePublicSale(uint256 _MAX_SUPPLY) external onlyOwner {
        require(_MAX_SUPPLY <= 4000, "max 4000");
        MAX_SUPPLY = _MAX_SUPPLY;
    }

    function publicMint(uint256[] memory tokenIdsToCheck) public {
        require(tokenIdsToCheck.length < 30, "Max 30 mints at one transaction");
        uint256[] memory tokenIds = unclaimedMutantApeDads(_msgSender(), tokenIdsToCheck);
        uint256 count = tokenIds.length;
        uint256 totalSupply = _owners.length;

        require(count > 0, "You dont have any ApeDads to mutate");
        uint256 serumBalance = ApeDadsJuice(apeDadsSerumContract).balanceOf(_msgSender(), 0);
        require(serumBalance > 0, "You dont have any serum");

        require(totalSupply + count <= MAX_SUPPLY, "Exceeds max supply.");

        uint256 countToMint = count >= serumBalance ? serumBalance : count;

        for (uint i; i < countToMint; i++) {
            mutantApeDadsClaimed[tokenIds[i]] = true;
            claimedIds.push(tokenIds[i]);
            emit MutantApeDadsClaimed(tokenIds[i]);
            _mint(_msgSender(), tokenIds[i]);
        }
        ApeDadsJuice(apeDadsSerumContract).burn(countToMint);
    }

    function adminMint(uint256[] memory tokenIdsToCheck, address[] memory minters) public onlyOwner {
        require(tokenIdsToCheck.length < 30, "Max 30 mints at one transaction");

        for (uint i; i < tokenIdsToCheck.length; i++) {
            mutantApeDadsClaimed[tokenIdsToCheck[i]] = true;
            claimedIds.push(tokenIdsToCheck[i]);
            emit MutantApeDadsClaimed(tokenIdsToCheck[i]);
            _mint(minters[i], tokenIdsToCheck[i]);
        }

    }

    function getClaimedIds() public view returns(uint256[] memory) {
        return claimedIds;
    }

    function unclaimedMutantApeDads(address account, uint256[] memory tokenIdsToCheck) public view returns (uint256[] memory) {
        uint256 unclaimedCount = 0;
        uint256 latestIndex = 0;
        uint256 length = tokenIdsToCheck.length;
        uint256[] memory tokenIds = new uint256[](length);

        for (uint i; i < length; i++) {
            require(ApeDads(apeDadsContract).ownerOf(tokenIdsToCheck[i]) == account, "Not your token");
            tokenIds[i] = tokenIdsToCheck[i];

            if (mutantApeDadsClaimed[tokenIdsToCheck[i]]) {
                continue;
            }

            unclaimedCount++;
        }

        uint256[] memory unclaimedMutantApeDadsOfUser = new uint256[](unclaimedCount);
        for (uint i; i < length; i++) {
            if (mutantApeDadsClaimed[tokenIds[i]]) {
                continue;
            }
            unclaimedMutantApeDadsOfUser[latestIndex] = tokenIds[i];
            latestIndex++;
        }

        return unclaimedMutantApeDadsOfUser;
    }

    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved to burn.");
        _burn(tokenId);
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) return new uint256[](0);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function batchTransferFrom(address _from, address _to, uint256[] memory _tokenIds) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            transferFrom(_from, _to, _tokenIds[i]);
        }
    }

    function batchSafeTransferFrom(address _from, address _to, uint256[] memory _tokenIds, bytes memory data_) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            safeTransferFrom(_from, _to, _tokenIds[i], data_);
        }
    }

    function isOwnerOf(address account, uint256[] calldata _tokenIds) external view returns (bool){
        for (uint256 i; i < _tokenIds.length; ++i) {
            if (_owners[_tokenIds[i]] != account)
                return false;
        }

        return true;
    }

    function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == operator || projectProxy[operator]) return true;
        return super.isApprovedForAll(_owner, operator);
    }

    function _mint(address to, uint256 tokenId) internal virtual override {
        _owners.push(to);
        emit Transfer(address(0), to, tokenId);
    }
}
//
//contract OwnableDelegateProxy { }
//contract OpenSeaProxyRegistry {
//    mapping(address => OwnableDelegateProxy) public proxies;
//}
