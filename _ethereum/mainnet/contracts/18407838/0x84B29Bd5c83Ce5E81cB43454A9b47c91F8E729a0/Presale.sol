// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.18;
pragma abicoder v2;

// Base contracts
import "./Owned.sol";
import "./SafeTransferLib.sol";
import "./MerkleProofLib.sol";
import "./HotWheels.sol";
import "./console2.sol";

contract HotWheelsPresale is Owned {
    error AlreadyClaimed();
    error NotAllowed();
    error NotEnoughEth();
    error MismatchedArrayLen();

    HotWheels public immutable token;

    // Address -> uint256 wei
    mapping(address => uint256) public amount;
    mapping(address => bool) public claimed;

    constructor(address owner, address tokenContract) Owned(owner) {
        token = HotWheels(payable(tokenContract));

        amount[0x41De8aC571734c4cD433eC3A823dFe7646580FDf] = 200_000_000 gwei;

        amount[0x60Ace3888a76ea543b23d189920E79c523A3bFfF] = 200_000_000 gwei;
        amount[0x9E11Bd94BaA91AE1426903D09311a0bE96f90914] = 200_000_000 gwei;
        amount[0xB82880291287F732EC2872d31e7E0111DD63968B] = 100_000_000 gwei;

        amount[0x39c5eFF325e4443c367DD418C92c687295E00b0b] = 400_000_000 gwei;
        amount[0xD2992D4D9aE365dF613C721349F8a25F609C4738] = 250_000_000 gwei;
        amount[0x5584DbD7739c6B73dced68f27630d34C1BFd3d33] = 250_000_000 gwei;
        amount[0x2b0f618C35008596287B0a5345C767BA12916213] = 300_000_000 gwei;

        amount[0x988a1AadFdf50D1a54F813D377fc570254D7EbbE] = 200_000_000 gwei;

        amount[0x4Bf4975a27C492c697204bf444B349DbEc137AE2] = 200_000_000 gwei;
        amount[0xCa15e07010F2d2e3ADAa93FC60D767Ea680566Cc] = 200_000_000 gwei;
        amount[0xeb42D6011f27A64a00A3B76B6702355694522355] = 200_000_000 gwei;

        amount[0x4306517ea02aE9D3417596217B1a8C3Db526d891] = 200_000_000 gwei;

        amount[0x050A01680dEA7604431da61C1FC25BD5541031c0] = 500_000_000 gwei;
        amount[0x6523694777827053d04cc6214310d6F873Dd2056] = 500_000_000 gwei;
    }

    receive() external payable {}

    function addWhitelisted(address[] calldata buyers, uint256[] calldata amounts) external onlyOwner {
        uint256 length = buyers.length;

        if (buyers.length != amounts.length) revert MismatchedArrayLen();
        for (uint256 i = 0; i < length; i++) {
            amount[buyers[i]] = amounts[i];
        }
    }

    function claim() external payable {
        if (claimed[msg.sender]) revert AlreadyClaimed();

        uint256 exchange_amount = amount[msg.sender];
        if (exchange_amount == 0) revert NotAllowed();
        if (exchange_amount > msg.value) revert NotEnoughEth();

        claimed[msg.sender] = true;

        SafeTransferLib.safeTransfer(token, msg.sender, (exchange_amount / 10000 gwei) * 1 ether);
    }

    function withdraw() external onlyOwner {
        SafeTransferLib.safeTransferETH(owner, address(this).balance);
    }
}
