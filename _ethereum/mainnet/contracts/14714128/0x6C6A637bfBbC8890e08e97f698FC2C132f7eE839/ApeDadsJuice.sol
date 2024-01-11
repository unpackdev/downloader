// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./ERC1155.sol";
import "./ApeDads.sol";

contract ApeDadsJuice is ERC1155, Ownable {
    uint256 public constant SERUM = 0;

    string  public              baseURI;
    string  public              name = 'ApeDadsJuice';

    address public              proxyRegistryAddress;
    address public              apeDadsContract;
    address public              mutantApeDadsContract;

    uint256 public              MAX_SUPPLY;
    uint256 public              totalSupply;

    mapping(address => bool) public projectProxy;
    mapping(uint256 => bool) public serumClaimed; // holds apedads nft ids
    uint256[] private claimedIds;

    event SerumClaimed(uint256 apeDadsId);

    constructor(
        string memory _baseURI,
        address _proxyRegistryAddress,
        address _apeDadsContract
    )
    ERC1155(_baseURI)
    {
        baseURI = _baseURI;
        proxyRegistryAddress = _proxyRegistryAddress;
        apeDadsContract = _apeDadsContract;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function uri(uint256) public view virtual override returns (string memory) {
        return baseURI;
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
        uint256[] memory tokenIds = unclaimedSerums(_msgSender(), tokenIdsToCheck);
        uint256 count = tokenIds.length;
        require(count > 0, "No serums to claim");
        require(totalSupply + count <= MAX_SUPPLY, "Exceeds max supply.");

        uint256 mintAmount;

        for (uint i; i < count; i++) {
            serumClaimed[tokenIds[i]] = true;
            claimedIds.push(tokenIds[i]);
            emit SerumClaimed(tokenIds[i]);
            mintAmount++;
        }
        ERC1155._mint(_msgSender(), SERUM, mintAmount, "");
        totalSupply += mintAmount;
    }

    function getClaimedIds() public view returns(uint256[] memory) {
        return claimedIds;
    }

    function unclaimedSerums(address account, uint256[] memory tokenIdsToCheck) public view returns (uint256[] memory) {
        uint256 unclaimedCount = 0;
        uint256 latestIndex = 0;
        uint256 length = tokenIdsToCheck.length;
        uint256[] memory tokenIds = new uint256[](length);

        for (uint i; i < length; i++) {
            require(ApeDads(apeDadsContract).ownerOf(tokenIdsToCheck[i]) == account, "Not your token");
            tokenIds[i] = tokenIdsToCheck[i];

            if (serumClaimed[tokenIdsToCheck[i]]) {
                continue;
            }

            unclaimedCount++;
        }

        uint256[] memory unclaimedSerumsOfUser = new uint256[](unclaimedCount);
        for (uint i; i < length; i++) {
            if (serumClaimed[tokenIds[i]]) {
                continue;
            }
            unclaimedSerumsOfUser[latestIndex] = tokenIds[i];
            latestIndex++;
        }

        return unclaimedSerumsOfUser;
    }

    function setMutantApeDadsContract(address newAddress) external onlyOwner {
        mutantApeDadsContract = newAddress;
    }

    function burn(uint256 amount) public {
        require(_msgSender() == mutantApeDadsContract, "Not allowed");
        ERC1155._burn(tx.origin, SERUM, amount);
    }

    function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == operator || projectProxy[operator]) return true;
        return ERC1155.isApprovedForAll(_owner, operator);
    }

}

//contract OwnableDelegateProxy { }
//contract OpenSeaProxyRegistry {
//    mapping(address => OwnableDelegateProxy) public proxies;
//}
