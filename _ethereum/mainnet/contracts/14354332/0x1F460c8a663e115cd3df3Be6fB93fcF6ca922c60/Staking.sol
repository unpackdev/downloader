//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./IERC1155Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./ERC1155HolderUpgradeable.sol";
import "./ERC721HolderUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PRBMathUD60x18.sol";
import "./Collections.sol";
import "./AdminManager.sol";
import "./IRaks.sol";

contract Staking is
    Initializable,
    ERC1155HolderUpgradeable,
    ERC721HolderUpgradeable,
    ReentrancyGuardUpgradeable,
    AdminManagerUpgradable
{
    using PRBMathUD60x18 for uint256;
    using Collections for Collections.LinkedList;

    uint256 public constant PLOT_ID = 0;

    IERC1155Upgradeable _plotToken;
    IERC721Upgradeable _strainToken;
    IERC721Upgradeable _bredStrainToken;
    IRaks _raksToken;

    uint256 private _baseCapacity;
    uint256 private _plotCapacity;
    uint256 private _accrualTime;

    struct StakerData {
        uint256 plotBalances;
        uint256 strainBalances;
        uint256 claims;
        uint256 lastClaims;
        Collections.LinkedList pendingClaims;
    }

    mapping(uint256 => address) private _strainOwners;
    mapping(uint256 => address) private _bredStrainOwners;
    mapping(address => StakerData) private _stakersData;
    mapping(uint256 => uint256) private _raksPerSecondCache;
    mapping(uint256 => bool) _spentBredStrains;

    event Stake(
        address indexed account,
        uint256 plotsAmount,
        uint256[] strainIds,
        uint256[] bredStrainIds
    );

    event Withdraw(
        address indexed account,
        uint256 plotsAmount,
        uint256[] strainIds,
        uint256[] bredStrainIds
    );

    event Claim(address indexed account);

    function initialize(
        address plotToken,
        address strainToken,
        address bredStrainToken,
        address raksToken
    ) public initializer {
        __ERC1155Holder_init();
        __ERC721Holder_init();
        __ReentrancyGuard_init();
        __AdminManager_init();
        _plotToken = IERC1155Upgradeable(plotToken);
        _strainToken = IERC721Upgradeable(strainToken);
        _bredStrainToken = IERC721Upgradeable(bredStrainToken);
        _raksToken = IRaks(raksToken);
        _baseCapacity = 5;
        _plotCapacity = 5;
        _accrualTime = 10 days;
        _raksPerSecondCache[1] = _calculateRaksPerSecond(1);
        _raksPerSecondCache[2] = _calculateRaksPerSecond(2);
        _raksPerSecondCache[3] = _calculateRaksPerSecond(3);
        _raksPerSecondCache[4] = _calculateRaksPerSecond(4);
        _raksPerSecondCache[5] = _calculateRaksPerSecond(5);
        _raksPerSecondCache[6] = _calculateRaksPerSecond(6);
        _raksPerSecondCache[7] = _calculateRaksPerSecond(7);
        _raksPerSecondCache[8] = _calculateRaksPerSecond(8);
        _raksPerSecondCache[9] = _calculateRaksPerSecond(9);
        _raksPerSecondCache[10] = _calculateRaksPerSecond(10);
    }

    function stake(
        uint256 plotsAmount,
        uint256[] memory strainIds,
        uint256[] memory bredStrainIds
    ) external nonReentrant {
        uint256 amount = strainIds.length + bredStrainIds.length;
        require(
            _getCapacity(_stakersData[msg.sender].plotBalances + plotsAmount) >=
                _stakersData[msg.sender].strainBalances + amount,
            "Not enough space in plots"
        );
        stakePlots(plotsAmount);
        stakeStrains(strainIds);
        stakeBredStrains(bredStrainIds);
        _updateClaims();
        _stakersData[msg.sender].plotBalances += plotsAmount;
        _stakersData[msg.sender].strainBalances += amount;
        emit Stake(msg.sender, plotsAmount, strainIds, bredStrainIds);
    }

    function stakePlots(uint256 amount) internal {
        if (amount > 0) {
            _plotToken.safeTransferFrom(
                msg.sender,
                address(this),
                PLOT_ID,
                amount,
                ""
            );
        }
    }

    function stakeStrains(uint256[] memory strainIds) internal {
        uint256 amount = strainIds.length;
        for (uint256 i = 0; i < amount; i++) {
            _strainToken.safeTransferFrom(
                msg.sender,
                address(this),
                strainIds[i]
            );
            _strainOwners[strainIds[i]] = msg.sender;
        }
    }

    function stakeBredStrains(uint256[] memory bredStrainIds) internal {
        uint256 amount = bredStrainIds.length;
        for (uint256 i = 0; i < amount; i++) {
            require(
                !_spentBredStrains[bredStrainIds[i]],
                "Staking a spent strain"
            );
            _bredStrainToken.safeTransferFrom(
                msg.sender,
                address(this),
                bredStrainIds[i]
            );
            _bredStrainOwners[bredStrainIds[i]] = msg.sender;
            _stakersData[msg.sender].pendingClaims.addNode(
                bredStrainIds[i],
                block.timestamp + _accrualTime
            );
        }
    }

    function withdraw(
        uint256 plotsAmount,
        uint256[] memory strainIds,
        uint256[] memory bredStrainIds
    ) external nonReentrant {
        uint256 amount = strainIds.length + bredStrainIds.length;
        require(
            _stakersData[msg.sender].plotBalances >= plotsAmount,
            "Not enough plots staked"
        );
        require(
            _stakersData[msg.sender].strainBalances >= amount,
            "Not enough strains staked"
        );
        require(
            _getCapacity(_stakersData[msg.sender].plotBalances - plotsAmount) >=
                _stakersData[msg.sender].strainBalances - amount,
            "Plots are currently in use"
        );
        withdrawPlots(plotsAmount);
        withdrawStrains(strainIds);
        withdrawBredStrains(bredStrainIds);
        _updateClaims();
        _stakersData[msg.sender].plotBalances -= plotsAmount;
        _stakersData[msg.sender].strainBalances -= strainIds.length;
        emit Withdraw(msg.sender, plotsAmount, strainIds, bredStrainIds);
    }

    function withdrawPlots(uint256 amount) internal {
        if (amount > 0) {
            _plotToken.safeTransferFrom(
                address(this),
                msg.sender,
                PLOT_ID,
                amount,
                ""
            );
        }
    }

    function withdrawStrains(uint256[] memory strainIds) internal {
        uint256 amount = strainIds.length;
        for (uint256 i = 0; i < amount; i++) {
            require(
                _strainOwners[strainIds[i]] == msg.sender,
                "Not original owner"
            );
            delete _strainOwners[strainIds[i]];
            _strainToken.safeTransferFrom(
                address(this),
                msg.sender,
                strainIds[i]
            );
        }
    }

    function withdrawBredStrains(uint256[] memory bredStrainIds) internal {
        uint256 amount = bredStrainIds.length;
        for (uint256 i = 0; i < amount; i++) {
            require(
                _bredStrainOwners[bredStrainIds[i]] == msg.sender,
                "Not original owner"
            );
            require(
                _stakersData[msg.sender].pendingClaims.nodeToValue[
                    bredStrainIds[i]
                ] <= block.timestamp,
                "Strain not fully spent"
            );
            _spentBredStrains[bredStrainIds[i]] = true;
            delete _bredStrainOwners[bredStrainIds[i]];
            _bredStrainToken.safeTransferFrom(
                address(this),
                msg.sender,
                bredStrainIds[i]
            );
        }
    }

    function claim() external nonReentrant {
        _updateClaims();
        _raksToken.mint(
            msg.sender,
            PRBMathUD60x18.toUint(_stakersData[msg.sender].claims)
        );
        _stakersData[msg.sender].claims = 0;
        emit Claim(msg.sender);
    }

    function _updateClaims() private {
        Collections.LinkedList storage pendingClaims = _stakersData[msg.sender]
            .pendingClaims;
        uint256 currentNodeId = pendingClaims.nodeLinks[0];
        uint256 currentStrainBalance = _stakersData[msg.sender].strainBalances;
        uint256 currentClaims = _stakersData[msg.sender].claims;
        uint256 lastClaim = _stakersData[msg.sender].lastClaims;
        uint256 secondsElapsed;
        while (currentNodeId != 0) {
            uint256 nextNodeId = pendingClaims.nodeLinks[currentNodeId];
            if (pendingClaims.nodeToValue[currentNodeId] <= block.timestamp) {
                uint256 timestamp = pendingClaims.nodeToValue[currentNodeId];
                secondsElapsed = timestamp - lastClaim;
                currentClaims +=
                    _calculateRaksPerSecond(currentStrainBalance) *
                    secondsElapsed;
                lastClaim = timestamp;
                currentStrainBalance--;
                pendingClaims.removeNode(currentNodeId);
            } else {
                break;
            }
            currentNodeId = nextNodeId;
        }
        secondsElapsed = block.timestamp - lastClaim;
        currentClaims +=
            _calculateRaksPerSecond(currentStrainBalance) *
            secondsElapsed;
        _stakersData[msg.sender].strainBalances = currentStrainBalance;
        _stakersData[msg.sender].claims = currentClaims;
        _stakersData[msg.sender].lastClaims = block.timestamp;
    }

    function _calculateRaksPerSecond(uint256 number) private returns (uint256) {
        if (_raksPerSecondCache[number] != 0) {
            return _raksPerSecondCache[number];
        }
        uint256 result = PRBMathUD60x18
            .fromUint(number)
            .pow(1_100000000000000000)
            .div(PRBMathUD60x18.fromUint(864));
        _raksPerSecondCache[number] = result;
        return result;
    }

    function _getCapacity(uint256 plotsAmount) private view returns (uint256) {
        return plotsAmount * _plotCapacity + _baseCapacity;
    }

    function setBaseCapacity(uint256 baseCapacity) external onlyAdmin {
        _baseCapacity = baseCapacity;
    }

    function setPlotCapacity(uint256 plotCapacity) external onlyAdmin {
        _plotCapacity = plotCapacity;
    }

    function setAccrualTime(uint256 accrualTime) external onlyAdmin {
        _accrualTime = accrualTime;
    }

    function setPlotToken(address plotTokenAddress) external onlyAdmin {
        _plotToken = IERC1155Upgradeable(plotTokenAddress);
    }

    function setStrainToken(address strainTokenAddress) external onlyAdmin {
        _strainToken = IERC721Upgradeable(strainTokenAddress);
    }

    function setBredStrainToken(address strainTokenAddress) external onlyAdmin {
        _strainToken = IERC721Upgradeable(strainTokenAddress);
    }

    function setRaksToken(address raksTokenAddress) external onlyAdmin {
        _raksToken = IRaks(raksTokenAddress);
    }
}
