pragma solidity ^0.5.17;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

interface Incentivizer {
    function initialize(address registry, uint256 start, uint256 duration) external;
    function setRewardDistribution(address distributor) external;
    function notifyRewardAmount(uint256 reward) external;
}

interface HAM {
    function mint(address to, uint256 amount) external;
}

contract IncentivizerRegistry is Ownable {
    using SafeMath for uint256;

    Incentivizer[] public incentivizers;
    IERC20 public ham;

    event NewIncentivizer(address indexed newIncentivizer, uint256 start, uint256 duration);

    constructor (IERC20 _ham) public {
        incentivizers = new Incentivizer[](0);
        ham = _ham;
    }

    function addNewIncentivizer(Incentivizer newIncentivizer, uint256 start, uint256 duration)
        public onlyOwner
    {
        incentivizers.push(newIncentivizer);
        newIncentivizer.initialize(address(this), start, duration);

        newIncentivizer.setRewardDistribution(address(this));
        newIncentivizer.notifyRewardAmount(0);

        emit NewIncentivizer(address(newIncentivizer), start, duration);
    }

    function removeIncentivizer(address oldIncentivizer) public onlyOwner {
        require(incentivizers.length > 0, "not found");
        uint i;
        for (i = 0; i < incentivizers.length; i++) {
            if (address(incentivizers[i]) == oldIncentivizer) {
                break;
            }
        }
        require(i < incentivizers.length, "not found");
        incentivizers[i] = incentivizers[incentivizers.length - 1];
        delete incentivizers[incentivizers.length - 1];
    }

    function mint(address recipient, uint256 amount) external {
        bool found = false;
        for (uint i = 0; i < incentivizers.length; i++) {
            if (address(incentivizers[i]) == msg.sender) {
                found = true;
                break;
            }
        }
        require(found, "!incentivizer");
        HAM(address(ham)).mint(recipient, amount);
    }
}
