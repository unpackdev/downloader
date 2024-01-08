// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Contracts
import "./Ownable.sol";

// Interfaces
import "./IERC165.sol";
import "./IImpactTheoryFoundersKey.sol";
import "./IITFKFreeMintable.sol";

contract ITFKPeer is Ownable {
    IImpactTheoryFoundersKey private itfk;

    mapping(address => bool) private _approvedContracts;
    mapping(uint256 => uint8) private _fkFreeMintUsage;
    mapping(uint256 => mapping(uint8 => address))
        private _fkFreeMintUsageContract;

    // Constructor
    constructor(address _itfkContractAddress) {
        itfk = IImpactTheoryFoundersKey(_itfkContractAddress);
    }

    function addFreeMintableContracts(address[] memory _contracts)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _contracts.length; i++) {
            require(
                IERC165(_contracts[i]).supportsInterface(
                    type(IITFKFreeMintable).interfaceId
                ),
                "Contract is not ITFKFreeMintable"
            );

            _approvedContracts[_contracts[i]] = true;
        }
    }

    function getFreeMintsRemaining(uint256 _tokenId)
        public
        view
        returns (uint8)
    {
        (uint256 tierId, ) = itfk.tokenTier(_tokenId);
        if (tierId == 1)
            // Legendary
            return
                _fkFreeMintUsage[_tokenId] > 3
                    ? 0
                    : 3 - _fkFreeMintUsage[_tokenId];
        if (tierId == 2)
            // Heroic
            return _fkFreeMintUsage[_tokenId] == 0 ? 1 : 0;
        return 0;
    }

    function updateFreeMintAllocation(uint256 _tokenId) public {
        require(_approvedContracts[msg.sender], "Not a free mintable contract");
        (uint256 tierId, ) = itfk.tokenTier(_tokenId);

        require(
            tierId == 1 || tierId == 2,
            "Only Legendary & Heroic can free mint"
        );

        if (tierId == 1)
            require(
                _fkFreeMintUsage[_tokenId] < 3,
                "All Legendary free mints used"
            );
        if (tierId == 2)
            require(_fkFreeMintUsage[_tokenId] < 1, "Heroic free mint used");

        uint8 newUsedFreeMint = _fkFreeMintUsage[_tokenId] + 1;
        _fkFreeMintUsageContract[_tokenId][newUsedFreeMint] = msg.sender;
        _fkFreeMintUsage[_tokenId] = newUsedFreeMint;
    }

    function getFreeMintContracts(uint256 _tokenId)
        external
        view
        returns (address[] memory contracts)
    {
        uint8 usageCount = _fkFreeMintUsage[_tokenId];
        address[] memory _contracts = new address[](usageCount);

        for (uint8 i; i < usageCount; i++) {
            _contracts[i] = _fkFreeMintUsageContract[_tokenId][i + 1];
        }

        return _contracts;
    }

    function getFoundersKeysByTierIds(address _wallet, uint8 _includeTier)
        external
        view
        returns (uint256[] memory fks)
    {
        // _includeTier = 3 bit field
        // 100 = relentless
        // 010 = heroic
        // 001 = legendary
        uint256 balance = itfk.balanceOf(_wallet);
        uint256[] memory fkMapping = new uint256[](balance);
        uint256 fkCount;

        for (uint256 i; i < balance; i++) {
            uint256 tokenId = itfk.tokenOfOwnerByIndex(_wallet, i);

            (uint256 tierId, ) = itfk.tokenTier(tokenId);
            uint8 bitFieldTierId = tierId > 0 ? uint8(1 << (tierId - 1)) : 0;
            if (_includeTier & bitFieldTierId != 0) {
                fkMapping[fkCount] = tokenId;
                fkCount++;
            }
        }

        uint256[] memory _fks = new uint256[](fkCount);
        for (uint256 i; i < fkCount; i++) {
            _fks[i] = fkMapping[i];
        }

        return _fks;
    }
}
