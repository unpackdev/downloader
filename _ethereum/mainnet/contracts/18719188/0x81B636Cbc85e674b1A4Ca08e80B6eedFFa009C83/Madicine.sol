// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC1155.sol";
import "./Ownable.sol";

contract Madicine is ERC1155, Ownable {
    event Prescribe(address indexed addr, uint256 indexed madicineId, uint256 indexed oozId);

    struct MadicineInfo {
        uint16 maxSupply;
        uint16 walletLimit;
        bool prescribeAllowed;
        address prescribeCosigner;
        uint16 mintCount;
        uint16 currentStageId;
        uint16 pointerId;
        bool isReversed;
        uint80 ethCost;
        uint80 ip3Cost;
        uint56 prescribeEndTime;
    }
    struct StageInfo {
        uint56 startTime;
        uint56 endTime;
        bool mintAllowed;
        uint8 mintMethod;
        uint80 ethPrice;
		uint16 maxSupply;
        uint16 walletLimit;
        uint16 mintCount;
        bytes32 merkleRoot;
        address cosigner;
        uint80 ip3Price;
        uint16 nPerMate;
    }

    mapping(uint256 => MadicineInfo) private _madicineInfo;
    mapping(uint256 => bool) private _madicineExists;
    mapping(uint256 => string) private _metadataUri;
    mapping(uint256 => mapping(uint256 => StageInfo)) private _stageInfo;

    mapping(uint256 => int16[10000]) private _prescribed;
    uint16[][10000] private _prescribedMadicine;

    mapping(uint256 => uint256) private _totalSupply;
    mapping(uint256 => mapping(address => uint256)) private _numberMinted;
    mapping(uint256 => mapping(uint256 => mapping(address => uint256))) private _stageMintedCountsPerWallet;
    mapping(address => uint256) private _totalPrescribed;

    address public utilContract;
    bool private contractInitialized;
    
    constructor() ERC1155("") {}

    function name() external pure returns (string memory) {
        return "OOZ Mad-icine";
    }
    
    function symbol() external pure returns (string memory) {
        return "OOZMAD";
    }

    function getMadicineInfo(uint256 madicineId) external view returns (MadicineInfo memory) {
        require(_madicineExists[madicineId], "Madicine ID does not exist");

        return _madicineInfo[madicineId];
    }

    function getStageInfo(uint256 madicineId, uint256 stageId) external view returns (StageInfo memory) {
        require(_madicineExists[madicineId], "Madicine ID does not exist");
        require(stageId > 0 && stageId <= _madicineInfo[madicineId].currentStageId, "Stage ID does not exist");

        return _stageInfo[madicineId][stageId];
    }

    function totalSupply(uint256[] calldata madicineIds) external view returns (uint256[] memory) {
        uint256[] memory batchSupply = new uint256[](madicineIds.length);

        for (uint256 i = 0; i < madicineIds.length; ++i) {
            require(_madicineExists[madicineIds[i]], "Madicine ID does not exist");
            batchSupply[i] = _totalSupply[madicineIds[i]];
        }

        return batchSupply;
    }

    function numberMintedBy(uint256 madicineId, address addr) external view returns (uint256) {
        require(_madicineExists[madicineId], "Madicine ID does not exist");

        return _numberMinted[madicineId][addr];
    }

    function stageMintedBy(uint256 madicineId, uint256 stageId, address addr) external view returns (uint256) {
        require(_madicineExists[madicineId], "Madicine ID does not exist");
        require(stageId > 0 && stageId <= _madicineInfo[madicineId].currentStageId, "Stage ID does not exist");

        return _stageMintedCountsPerWallet[madicineId][stageId][addr];
    }

    function totalPrescribedBy(address addr) external view returns (uint256) {
        return _totalPrescribed[addr];
    }

    function prescribedMadicineOf(uint256 oozId) external view returns (uint16[] memory) {
        require(oozId > 0 && oozId < 10000, "OOZ ID does not exist");

        return _prescribedMadicine[oozId];
    }
    
    function isPrescribed(uint256 madicineId, uint256 oozId) public view returns (bool) {
        require(_madicineExists[madicineId], "Madicine ID does not exist");
        require(oozId > 0 && oozId < 10000, "OOZ ID does not exist");

        return _prescribed[madicineId][oozId] == int(madicineId);
    }

    function canPrescribe(uint256 madicineId, uint256 oozId) public view returns (bool) {
        require(_madicineExists[madicineId], "Madicine ID does not exist");
        require(oozId > 0 && oozId < 10000, "OOZ ID does not exist");

        if (!_madicineInfo[madicineId].isReversed) {
            if (!_madicineInfo[_madicineInfo[madicineId].pointerId].isReversed) {
                return (_prescribed[_madicineInfo[madicineId].pointerId][oozId] == 0) && (_prescribed[madicineId][oozId] == 0);
            } else {
                return (_prescribed[_madicineInfo[madicineId].pointerId][oozId] == -1) && (_prescribed[madicineId][oozId] == 0);
            }
        } else {
            if (!_madicineInfo[_madicineInfo[madicineId].pointerId].isReversed) {
                return (_prescribed[_madicineInfo[madicineId].pointerId][oozId] == 0) && (_prescribed[madicineId][oozId] == -1);
            } else {
                return (_prescribed[_madicineInfo[madicineId].pointerId][oozId] == -1) && (_prescribed[madicineId][oozId] == -1);
            }
        }
    }

    function canPrescribeNow(uint256 madicineId, uint256 oozId) public view returns (bool) {
        require(_madicineExists[madicineId], "Madicine ID does not exist");
        require(oozId > 0 && oozId < 10000, "OOZ ID does not exist");
        
        if (!_madicineInfo[madicineId].prescribeAllowed) {
            return false;
        }
        if (_madicineInfo[madicineId].prescribeEndTime != 0 && block.timestamp > _madicineInfo[madicineId].prescribeEndTime) {
            return false;
        }
        
        return canPrescribe(madicineId, oozId);
    }

    function uri(uint256 madicineId) public view virtual override returns (string memory) {
        require(_madicineExists[madicineId], "Madicine ID does not exist");

        return _metadataUri[madicineId];
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        return uri(tokenId);
    }

    function addMadicine(uint256 madicineId, uint16 maxSupply, uint16 walletLimit, bool prescribeAllowed, address prescribeCosigner, string calldata metadata, uint80 ethCost, uint80 ip3Cost, uint56 prescribeEndTime) public onlyOwner {
        require(!_madicineExists[madicineId], "Madicine ID already exists");
        require(madicineId > 0 && madicineId < 2 ** 15, "Madicine ID out of bounds");

        _madicineInfo[madicineId] = MadicineInfo({
            maxSupply: maxSupply,
            walletLimit: walletLimit,
            prescribeAllowed: prescribeAllowed,
            prescribeCosigner: prescribeCosigner,
            mintCount: 0,
            currentStageId: 0,
            pointerId: uint16(madicineId),
            isReversed: false,
            ethCost: ethCost,
            ip3Cost: ip3Cost,
            prescribeEndTime: prescribeEndTime
        });

        _madicineExists[madicineId] = true;
        _metadataUri[madicineId] = metadata;
    }

    function editMadicine(uint256 madicineId, uint16 maxSupply, uint16 walletLimit, address prescribeCosigner, string calldata metadata, uint80 ethCost, uint80 ip3Cost, uint56 prescribeEndTime) public onlyOwner {
        require(_madicineExists[madicineId], "Madicine ID does not exist");

        _madicineInfo[madicineId].maxSupply = maxSupply;
        _madicineInfo[madicineId].walletLimit = walletLimit;
        _madicineInfo[madicineId].prescribeCosigner = prescribeCosigner;
        _madicineInfo[madicineId].ethCost = ethCost;
        _madicineInfo[madicineId].ip3Cost = ip3Cost;
        _madicineInfo[madicineId].prescribeEndTime = prescribeEndTime;

        _metadataUri[madicineId] = metadata;
    }

    function invertPrescribeAllowed(uint256[] calldata madicineIds) public onlyOwner {
        for (uint256 i = 0; i < madicineIds.length; i++) {
            require(_madicineExists[madicineIds[i]], "Madicine ID does not exist");

            _madicineInfo[madicineIds[i]].prescribeAllowed = !_madicineInfo[madicineIds[i]].prescribeAllowed;
        }
    }

    function addStage(uint256 madicineId, uint56[2] calldata times, bool mintAllowed, uint8 mintMethod, uint80 ethPrice, uint16 maxSupply, uint16 walletLimit, bytes32 merkleRoot, address cosigner, uint80 ip3Price, uint16 nPerMate) public onlyOwner {
        require(_madicineExists[madicineId], "Madicine ID does not exist");

        _madicineInfo[madicineId].currentStageId++;

        _stageInfo[madicineId][_madicineInfo[madicineId].currentStageId] = StageInfo({
            startTime: times[0],
            endTime: times[1],
            mintAllowed: mintAllowed,
            mintMethod: mintMethod,
            ethPrice: ethPrice,
            maxSupply: maxSupply,
            walletLimit: walletLimit,
            mintCount: 0,
            merkleRoot: merkleRoot,
            cosigner: cosigner,
            ip3Price: ip3Price,
            nPerMate: nPerMate
        });
    }

    function editStage(uint256 madicineId, uint256 stageId, uint56[2] calldata times, uint8 mintMethod, uint80 ethPrice, uint16 maxSupply, uint16 walletLimit, bytes32 merkleRoot, address cosigner, uint80 ip3Price, uint16 nPerMate) public onlyOwner {
        require(_madicineExists[madicineId], "Madicine ID does not exist");
        require(stageId > 0 && stageId <= _madicineInfo[madicineId].currentStageId, "Stage ID does not exist");
        require(_stageInfo[madicineId][stageId].mintCount == 0, "Stage has already started");

        _stageInfo[madicineId][stageId].startTime = times[0];
        _stageInfo[madicineId][stageId].endTime = times[1];
        _stageInfo[madicineId][stageId].mintMethod = mintMethod;
        _stageInfo[madicineId][stageId].ethPrice = ethPrice;
        _stageInfo[madicineId][stageId].maxSupply = maxSupply;
        _stageInfo[madicineId][stageId].walletLimit = walletLimit;
        _stageInfo[madicineId][stageId].merkleRoot = merkleRoot;
        _stageInfo[madicineId][stageId].cosigner = cosigner;
        _stageInfo[madicineId][stageId].ip3Price = ip3Price;
        _stageInfo[madicineId][stageId].nPerMate = nPerMate;
    }

    function invertMintAllowed(uint256[] calldata madicineIds, uint256[] calldata stageIds) public onlyOwner {
        require(madicineIds.length == stageIds.length, "Array length not matching");

        for (uint256 i = 0; i < madicineIds.length; i++) {
            require(_madicineExists[madicineIds[i]], "Madicine ID does not exist");
            require(stageIds[i] > 0 && stageIds[i] <= _madicineInfo[madicineIds[i]].currentStageId, "Stage ID does not exist");

            _stageInfo[madicineIds[i]][stageIds[i]].mintAllowed = !_stageInfo[madicineIds[i]][stageIds[i]].mintAllowed;
        }
    }

    function ownerMint(uint256[] calldata madicineIds, address[] calldata to, uint256[] calldata amount) public onlyOwner {
        require(madicineIds.length == to.length && to.length == amount.length, "Array length not matching");

        for (uint256 i = 0; i < to.length; i++) {
            require(_madicineExists[madicineIds[i]], "Madicine ID does not exist");
            require(amount[i] + _madicineInfo[madicineIds[i]].mintCount <= _madicineInfo[madicineIds[i]].maxSupply, "Exceeds maximum madicine supply");

            _mint(to[i], madicineIds[i], amount[i], "");

            unchecked {
                _totalSupply[madicineIds[i]] += amount[i];
                _madicineInfo[madicineIds[i]].mintCount += uint16(amount[i]);
                _numberMinted[madicineIds[i]][msg.sender] += amount[i];
            }
        }
    }

    function point(uint256[] calldata madicineIdsFrom, uint256[] calldata madicineIdsTo) public onlyOwner {
        require(madicineIdsFrom.length == madicineIdsTo.length, "Array length not matching");

        for (uint256 i = 0; i < madicineIdsFrom.length; i++) {
            require(_madicineExists[madicineIdsFrom[i]] && _madicineExists[madicineIdsTo[i]], "Madicine ID does not exist");

            _madicineInfo[madicineIdsFrom[i]].pointerId = uint16(madicineIdsTo[i]);
        }
    }

    function blacklist(uint256 madicineId, uint256[] calldata oozIds) public onlyOwner {
        require(_madicineExists[madicineId], "Madicine ID does not exist");

        for (uint256 i = 0; i < oozIds.length; i++) {
            require(oozIds[i] > 0 && oozIds[i] < 10000, "OOZ ID does not exist");
            require(_prescribed[madicineId][oozIds[i]] == 0, "Cannot blacklist this OOZ");

            _prescribed[madicineId][oozIds[i]] = -1;
        }
    }

    function unblacklist(uint256 madicineId, uint256[] calldata oozIds) public onlyOwner {
        require(_madicineExists[madicineId], "Madicine ID does not exist");

        for (uint256 i = 0; i < oozIds.length; i++) {
            require(oozIds[i] > 0 && oozIds[i] < 10000, "OOZ ID does not exist");
            require(_prescribed[madicineId][oozIds[i]] == -1, "OOZ not in blacklist");

            _prescribed[madicineId][oozIds[i]] = 0;
        }
    }

    function reverseMadicine(uint256[] calldata madicineIds) public onlyOwner {
        for (uint256 i = 0; i < madicineIds.length; i++) {
            require(_madicineExists[madicineIds[i]], "Madicine ID does not exist");
            require(_madicineInfo[madicineIds[i]].mintCount == _totalSupply[madicineIds[i]], "Prescribe already started");

            _madicineInfo[madicineIds[i]].isReversed = !_madicineInfo[madicineIds[i]].isReversed;
        }
    }

    function initializeUtilContract(address contractAddress) public onlyOwner {
        require(!contractInitialized, "Contract already initialized");

        utilContract = contractAddress;
        contractInitialized = true;
    }

    function mint(address to, uint256 madicineId, uint256 stageId, uint256 amount) public {
        require(msg.sender == utilContract, "Only util contract can call");
        require(amount > 0, "Mint amount must be greater than 0");

        _mint(to, madicineId, amount, "");

        unchecked {
            _totalSupply[madicineId] += amount;
            _madicineInfo[madicineId].mintCount += uint16(amount);
            _stageInfo[madicineId][stageId].mintCount += uint16(amount);
            _numberMinted[madicineId][to] += amount;
            _stageMintedCountsPerWallet[madicineId][stageId][to] += amount;
        }
    }

    function burn(address addr, uint256 madicineId, uint256 amount) public {
        require(msg.sender == utilContract, "Only util contract can call");
        require(amount > 0, "Burn amount must be greater than 0");

        _burn(addr, madicineId, amount);

        unchecked {
            _totalSupply[madicineId] -= amount;
        }
    }

    function prescribe(address addr, uint256 madicineId, uint256 oozId) public {
        require(msg.sender == utilContract, "Only util contract can call");

        _burn(addr, madicineId, 1);

        unchecked {
            --_totalSupply[madicineId];
            ++_totalPrescribed[addr];
        }

        _prescribed[_madicineInfo[madicineId].pointerId][oozId] = int16(int(madicineId));
        _prescribed[madicineId][oozId] = int16(int(madicineId));
        _prescribedMadicine[oozId].push(uint16(madicineId));

        emit Prescribe(addr, madicineId, oozId);
    }
    
    // Basic withdrawal of funds function in order to transfer ETH out of the smart contract
    function withdrawFunds() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}
}