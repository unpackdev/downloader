// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Math.sol";
import "./Address.sol";
import "./IERC721.sol";
import "./ERC721Holder.sol";

import "./IHegicBot.sol";
import "./IChainLinkFeed.sol";
import "./IKeep3rV1.sol";
import "./IKeep3rV1Helper.sol";
import "./Governable.sol";
import "./CollectableDust.sol";

contract HegicBotKeep3r is Governable, CollectableDust {
    using Address for address;
    using SafeMath for uint256;

    IChainLinkFeed public constant FASTGAS = IChainLinkFeed(0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C);
    IKeep3rV1 public keep3r = IKeep3rV1(0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44);

    uint256 public feeMultiplier = 11;
    uint256 public constant BASE = 10;

    IHegicBot public bot;
    uint256 internal _gasUsed;
    address internal ownerToPay;

    constructor(IHegicBot _bot) public Governable(msg.sender) CollectableDust() {
        bot = _bot;
    }

    function exercise(uint256 trackedTokenId) external paysKeeper {
        (ownerToPay, ) = bot.exercise(trackedTokenId);
    }

    function _isKeeper() internal {
        _gasUsed = gasleft();
        require(tx.origin == msg.sender, "keep3r::isKeeper:keeper-is-a-smart-contract");
        require(keep3r.isKeeper(msg.sender), "keep3r::isKeeper:keeper-is-not-registered");
    }

    modifier paysKeeper() {
        _isKeeper();
        _;

        uint256 gasPrice = Math.min(tx.gasprice, uint256(FASTGAS.latestAnswer()));
        uint256 keeperFee = gasPrice.mul(_gasUsed.sub(gasleft())).mul(feeMultiplier).div(BASE);

        payable(governor).transfer(keeperFee);
        payable(ownerToPay).transfer(address(this).balance);

        uint256 keeperFeeInKp3r = IKeep3rV1Helper(address(keep3r.KPRH())).quote(keeperFee);
        keep3r.workReceipt(msg.sender, keeperFeeInKp3r);
    }

    function setKeep3r(address _keep3r) external onlyGovernor {
        keep3r = IKeep3rV1(_keep3r);
    }

    function setBot(address _bot) external onlyGovernor {
        bot = IHegicBot(_bot);
    }

    function setFeeMultiplier(uint256 _feeMultiplier) external onlyGovernor {
        feeMultiplier = _feeMultiplier;
    }

    // Governable
    function setPendingGovernor(address _pendingGovernor) external override onlyGovernor {
        _setPendingGovernor(_pendingGovernor);
    }

    function acceptGovernor() external override onlyPendingGovernor {
        _acceptGovernor();
    }

    // Collectable Dust
    function sendDust(
        address _to,
        address _token,
        uint256 _amount
    ) external override onlyGovernor {
        _sendDust(_to, _token, _amount);
    }

    receive() external payable {}
}
