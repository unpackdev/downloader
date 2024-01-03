pragma solidity >=0.6.6;

import "./ReentrancyGuard.sol";
import "./TransferHelper.sol";
import "./Math.sol";
import "./SafeMath.sol";
import "./DistributionLibrary.sol";
import "./ICAVO.sol";
import "./IExcavoERC20.sol";
import "./IxCAVO.sol";
import "./IPublicPresale.sol";
import "./BaseCAVO.sol";

contract PublicPresale is BaseCAVO, IPublicPresale {
    
    using SafeMath for uint;
    using DistributionLibrary for DistributionLibrary.Data;

    event PublicPresalePurchase(address indexed recipient, uint amount);
    event PublicDistributed(address indexed recipient, uint amount);

    address public immutable override presaleOwner;
    uint private presaleDurationInBlocks;
    uint private presaleStartBlock;
    
    DistributionLibrary.Data private distribution;

    constructor(address _presaleOwner, uint32 _vestingBlocksInPeriod, uint _presaleDurationInBlocks) public {
        presaleOwner = _presaleOwner;
        distribution.blocksInPeriod = _vestingBlocksInPeriod;
        presaleDurationInBlocks = _presaleDurationInBlocks;
    }

    function availablePublicPresaleAmountOf(address account) external view override returns (uint) {
        return distribution.availableAmountOf(account);
    }

    function publicPresaleClaim(uint amount) external override nonReentrant {
        distribution.claim(amount);
        emit PublicDistributed(msg.sender, amount);
    }

    function startPublicPresaleDistribution() external override nonReentrant {
        require(presaleStartBlock != 0 && block.number >= presaleStartBlock.add(presaleDurationInBlocks), 'PublicPresale: INVALID_PARAMS');
        distribution.start();
    }

    function startPublicPresale() external override nonReentrant {
        require(presaleStartBlock == 0 && msg.sender == creator, 'PublicPresale: FORBIDDEN');
        presaleStartBlock = block.number;
    }

    receive() external payable nonReentrant {
        require(block.number >= presaleStartBlock && block.number < presaleStartBlock.add(presaleDurationInBlocks), 'PublicPresale: INACTIVE');
        // P = 0.5 ETH/CAVO
        uint mintedCAVO = msg.value.mul(100).div(50);
        payable(presaleOwner).transfer(msg.value);
        _mint(address(this), mintedCAVO);
        distribution.maxAmountOf[msg.sender] = distribution.maxAmountOf[msg.sender].add(mintedCAVO);
        emit PublicPresalePurchase(msg.sender, mintedCAVO);
    }
}