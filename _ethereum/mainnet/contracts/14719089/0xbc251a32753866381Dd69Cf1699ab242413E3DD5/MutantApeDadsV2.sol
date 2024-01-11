// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract MutantApeDadsV2 is ERC721, Ownable {
    uint256 public _totalSupply;

    string public provenanceHash;
    string public baseURI;

    address public              proxyRegistryAddress;
    uint256 public              MAX_SUPPLY;
    address public              apeDadsContract;
    address public              apeDadsSerumContract;

    mapping(uint256 => bool) public mutantApeDadsClaimed; // holds apedads nft ids
    uint256[] private claimedIds;
    mapping(address => bool) public projectProxy;

    event MutantApeDadsClaimed(uint256 apeDadsId);

    constructor(
        string memory _baseURL,
        address _proxyRegistryAddress,
        address _apeDadsContract,
        address _apeDadsSerumContract
    ) ERC721("Future ApeDads", "FUTDAD")
    {
        baseURI = _baseURL;
        proxyRegistryAddress = _proxyRegistryAddress;
        apeDadsContract = _apeDadsContract;
        apeDadsSerumContract = _apeDadsSerumContract;
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

        require(count > 0, "You dont have any ApeDads to mutate");
        uint256 serumBalance = IApeDadsJuice(apeDadsSerumContract).balanceOf(_msgSender(), 0);
        require(serumBalance > 0, "You dont have any serum");

        require(_totalSupply + count <= MAX_SUPPLY, "Exceeds max supply.");

        uint256 countToMint = count >= serumBalance ? serumBalance : count;

        for (uint i; i < countToMint; i++) {
            mutantApeDadsClaimed[tokenIds[i]] = true;
            claimedIds.push(tokenIds[i]);
            emit MutantApeDadsClaimed(tokenIds[i]);
            _mint(_msgSender(), tokenIds[i]);
            _totalSupply++;
        }
        IApeDadsJuice(apeDadsSerumContract).burn(countToMint);
    }

    function adminMint(uint256[] memory tokenIdsToCheck, address[] memory minters) public onlyOwner {
        require(tokenIdsToCheck.length < 30, "Max 30 mints at one transaction");
        require(_totalSupply + tokenIdsToCheck.length <= 4000, "Exceeds max supply.");

        for (uint i; i < tokenIdsToCheck.length; i++) {
            mutantApeDadsClaimed[tokenIdsToCheck[i]] = true;
            claimedIds.push(tokenIdsToCheck[i]);
            emit MutantApeDadsClaimed(tokenIdsToCheck[i]);
            _mint(minters[i], tokenIdsToCheck[i]);
            _totalSupply++;
        }

    }

    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved to burn.");
        _burn(tokenId);
    }

    function unclaimedMutantApeDads(address account, uint256[] memory tokenIdsToCheck) public view returns (uint256[] memory) {
        uint256 unclaimedCount = 0;
        uint256 latestIndex = 0;
        uint256 length = tokenIdsToCheck.length;
        uint256[] memory tokenIds = new uint256[](length);

        for (uint i; i < length; i++) {
            require(ERC721(apeDadsContract).ownerOf(tokenIdsToCheck[i]) == account, "Not your token");
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

    function setProvenanceHash(string memory newProvenanceHash) public onlyOwner {
        provenanceHash = newProvenanceHash;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == operator || projectProxy[operator]) return true;
        return super.isApprovedForAll(_owner, operator);
    }
}

contract OwnableDelegateProxy { }
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

interface IApeDadsJuice {
    function burn(uint256 amount) external;
    function balanceOf(address account, uint256 id) external returns (uint256);
}
