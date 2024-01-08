// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IInfinityProtocol.sol";

contract FeeDistributor is Ownable {
    using SafeMath for uint;

    struct FeeRecipient {
        address liquidVault;
        address secondaryAddress;
        uint256 liquidVaultShare; //percentage between 0 and 100
        uint256 burnPercentage;
    }
    
    IInfinityProtocol public infinity;
    FeeRecipient public recipients;

    bool public initialized;

    uint private constant MINIMUM_AMOUNT = 1e8;

    modifier seeded {
        require(
            initialized,
            "FeeDistributor: Fees cannot be distributed until Distributor seeded."
        );
        _;
    }

    function seed(
        address _infinity,
        address _vault,
        address _secondaryAddress,
        uint _liquidVaultShare,
        uint _burnPercentage
    ) external onlyOwner {
        require(
            _liquidVaultShare.add(_burnPercentage) <= 100,
            "FeeDistributor: liquidVault + burnPercentage incorrect sets"
        );
        infinity = IInfinityProtocol(_infinity);
        recipients.liquidVault = _vault;
        recipients.secondaryAddress = _secondaryAddress;
        recipients.liquidVaultShare = _liquidVaultShare;
        recipients.burnPercentage = _burnPercentage;
        initialized = true;
    }

    function distributeFees() external seeded {
        uint balance = infinity.balanceOf(address(this));

        if (balance < MINIMUM_AMOUNT) {
            return;
        }

        uint liquidShare;
        uint burningShare;
        uint secondaryShare;

        if (recipients.liquidVaultShare > 0) {
            liquidShare = recipients.liquidVaultShare.mul(balance).div(100);

            require(
                infinity.transfer(recipients.liquidVault, liquidShare),
                "FeeDistributor: transfer to LiquidVault failed"
            );
        }

        if (recipients.burnPercentage > 0) {
            burningShare = recipients.burnPercentage.mul(balance).div(100);
            infinity.burn(burningShare);
        }

        secondaryShare = balance.sub(liquidShare).sub(burningShare);
        if (secondaryShare > 0) {
            require(
            infinity.transfer(recipients.secondaryAddress, secondaryShare),
            "FeeDistributor: transfer to the secondary address failed"
        );
        }
    }
}