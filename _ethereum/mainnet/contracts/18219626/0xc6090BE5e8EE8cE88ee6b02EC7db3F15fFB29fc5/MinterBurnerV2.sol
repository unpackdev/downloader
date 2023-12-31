// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;


import "./ReentrancyGuardUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./IGoMiningToken.sol";
import "./IMintReward.sol";

contract MinterBurnerV2 is PausableUpgradeable, AccessControlUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable {
    using SafeERC20Upgradeable for IGoMiningToken;

    /// Base Token related information
    IGoMiningToken public Token;
    IMintReward public MintReward;

    struct MintReceiver {
        address receiver;
        uint16 deciPercents;
    }

    struct BurnAndMint {
        uint256 burntAmount;
        uint256 mintAmount;
        uint16 mintRewardDeciPercents;
        uint256 ts;
        uint256 blk;
    }

    struct ReceiverBurnAndMint {
        uint256 mintAmount;
        uint256 index;
        uint256 deciPercents;
        uint256 ts;
        uint256 blk;
    }

    MintReceiver[] public mintReceivers;

    uint16 public mintRewardDeciPercents;
    uint256 public mintBurnIndex;

    struct BurnRatioEpoch {
        uint256 volume;
        uint16 deciRatio;
    }

    mapping(uint256 => BurnAndMint) public burnAndMintHistory; // mintBurnIndex -> burn and mint
    mapping(address => mapping(uint256 => ReceiverBurnAndMint)) public receiverBurnAndMintHistory; // user -> ReceiverBurnAndMint[receiverMintBurnEpoch]
    mapping(address => uint256) public receiverBurnAndMintIndex;

    BurnRatioEpoch[] public burnRatioEpochs;
    uint256 public lastBurnRatio;

    mapping(address => uint256) public toBurnBalances; // user Deposits


    uint256 public burntAmount;
    uint256 public readyToBurn;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant SPENDER_ROLE = keccak256("SPENDER_ROLE");
    bytes32 public constant MINTER_AND_BURNER_ROLE = keccak256("MINTER_AND_BURNER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");
    bytes32 public constant TOKEN_OWNER_ROLE = keccak256("TOKEN_OWNER_ROLE");

    event SpentBalance(address indexed account, uint256 amount);
    event BurntAndMinted(uint256 burnt, uint256 minted, uint256 indexed index);
    event IncreasedAmount(address indexed account, uint256 amount);
    event Withdrawn(address indexed account, uint256 amount);


    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _checkTotalDeciPercents() internal view returns (uint16) {
        uint16 totalPercents = mintRewardDeciPercents;
        for (uint256 i = 0; i < mintReceivers.length; i++) {
            totalPercents += mintReceivers[i].deciPercents;
        }
        require(
            totalPercents <= 1000,
            "MinterBurner: deci-percent should be <= 1000"
        );
        return totalPercents;
    }

    // @notice Set deci-percent of mint reward contract
    // @param _deciPercents deci-percent (1000 = 100%)
    function setMintRewardDeciPercent(uint16 _deciPercents) external onlyRole(CONFIGURATOR_ROLE) {
        mintRewardDeciPercents = _deciPercents;
        _checkTotalDeciPercents();
    }

    // @notice Get array of current mint receivers
    function getMintReceivers() external view returns (MintReceiver[] memory) {
        return mintReceivers;
    }

    // @notice Add mint receiver
    // @param receiver is account to receive mint reward
    // @param deciPercents deci-percent (1000 = 100%)
    function addMintReceiver(
        address receiver,
        uint16 deciPercents
    ) external onlyRole(CONFIGURATOR_ROLE) {
        mintReceivers.push(MintReceiver(receiver, deciPercents));

        _checkTotalDeciPercents();
    }

    // @notice Remove mint receiver 'receiver'
    // @param receiver is account received mint reward
    function removeMintReceiver(address receiver) external onlyRole(CONFIGURATOR_ROLE) {
        for (uint256 i = 0; i < mintReceivers.length; i++) {
            if (mintReceivers[i].receiver == receiver) {
                _removeMintReceiver(i);
                return;
            }
        }
    }

    function _removeMintReceiver(uint256 index) internal {
        require(
            index < mintReceivers.length,
            "MinterBurner: index out of bounds"
        );
        mintReceivers[index] = mintReceivers[mintReceivers.length - 1];
        mintReceivers.pop();
    }

    // @notice Get current epoch of burn ratio
    // returns index at burnRatioEpochs
    // and amount left on current epoch
    function getBurnRatioIndexAndAmountToBurnOnCurrentEpoch()
    public
    view
    returns (uint256, uint256)
    {
        require(burnRatioEpochs.length > 0, "MinterBurner: no burn ratio epochs");

        uint256 burntSummary;
        uint256 burnRatioEpochsLength = burnRatioEpochs.length;
        for (uint256 i = 0; i < burnRatioEpochsLength; i++) {
            burntSummary += burnRatioEpochs[i].volume;
            if (burntAmount < burntSummary) {
                return (i, burntSummary - burntAmount);
            }
        }

        return (burnRatioEpochsLength - 1, 0);
    }

    // @notice Set last burn ratio, it's rate after epochs will be used
    // @param _lastBurnRatio is last burn ratio
    function setLastBurnRatio(uint16 _lastBurnRatio) external onlyRole(CONFIGURATOR_ROLE) {
        require(_lastBurnRatio <= 1000, "MinterBurner: ratio more than 1000");

        lastBurnRatio = _lastBurnRatio;
    }

    // @notice Add burn ratio epoch
    // @param volume is amount of tokens to burn with deciRatio
    // @param deciRatio is deci-percent of tokens to burn (1000 = 100%)
    function addBurnRatioEpoch(
        uint256 volume,
        uint16 deciRatio
    ) external onlyRole(CONFIGURATOR_ROLE) {
        require(volume > 0, "MinterBurner: volume is below zero or equals zero");
        require(deciRatio <= 1000, "MinterBurner: ratio more than 1000");
        burnRatioEpochs.push(BurnRatioEpoch(volume, deciRatio));
    }

    // @notice Clear all burn ratio epochs
    function clearBurnRatioEpochs() external onlyRole(CONFIGURATOR_ROLE) {
        delete burnRatioEpochs;
    }

    // @notice Get array of current burn ratio epochs
    function getBurnRatioEpochs()
    external
    view
    returns (BurnRatioEpoch[] memory)
    {
        // QUESTION: why not just return burnRatioEpochs (or just use burnRatioEpochs as public property)?
        return burnRatioEpochs;

    }

    // @notice Get amount of tokens to mint depends on `_amountToBurn`
    // tokens already burned are included to calculation
    // @param _amountToBurn is amount of tokens to burn
    function getAmountToMint(
        uint256 _amountToBurn
    ) public view returns (uint256) {
        uint256 amountToBurn = _amountToBurn;

        (
            uint256 burnRatioIndex,
            uint256 amountToBurnOnCurrentEpoch
        ) = getBurnRatioIndexAndAmountToBurnOnCurrentEpoch();

        if (amountToBurnOnCurrentEpoch > amountToBurn) {
            return
                amountToBurn *
                burnRatioEpochs[burnRatioIndex].deciRatio / 1000;
        } else {
            uint256 amountToMint = (amountToBurnOnCurrentEpoch *
                burnRatioEpochs[burnRatioIndex].deciRatio) / 1000;
            uint256 calculatedAmountToBurn = amountToBurnOnCurrentEpoch;
            while (calculatedAmountToBurn < amountToBurn) {
                burnRatioIndex++;

                if (burnRatioIndex == burnRatioEpochs.length) {
                    amountToMint +=
                        ((amountToBurn - calculatedAmountToBurn) *
                            lastBurnRatio) /
                        1000;
                    calculatedAmountToBurn = amountToBurn;
                } else {
                    BurnRatioEpoch memory burnRatioEpoch = burnRatioEpochs[
                                burnRatioIndex
                        ];
                    if (
                        burnRatioEpoch.volume >
                        amountToBurn - calculatedAmountToBurn
                    ) {
                        amountToMint +=
                            ((amountToBurn - calculatedAmountToBurn) *
                                burnRatioEpoch.deciRatio) /
                            1000;
                        calculatedAmountToBurn = amountToBurn;
                    } else {
                        amountToMint +=
                            (burnRatioEpoch.volume *
                                burnRatioEpoch.deciRatio) /
                            1000;
                        calculatedAmountToBurn += burnRatioEpoch.volume;
                    }
                }
            }

            return amountToMint;
        }
    }

    // @notice Burn tokens is ready to burn and mint calculated reward
    function burnAndMint() external onlyRole(MINTER_AND_BURNER_ROLE) {
        require(readyToBurn > 0, "MinterBurner: nothing to burn");

        require(
            Token.balanceOf(address(this)) >= readyToBurn,
            "MinterBurner: not enough balance"
        );

        uint256 amountToMint = getAmountToMint(readyToBurn);

        Token.burn(address(this), readyToBurn);

        burnAndMintHistory[mintBurnIndex] = BurnAndMint(
            readyToBurn,
            amountToMint,
            mintRewardDeciPercents,
            block.timestamp,
            block.number
        );

        burntAmount += readyToBurn;

        uint256 amountToMintForReward = (amountToMint * mintRewardDeciPercents) /
                    1000;
        Token.mint(address(this), amountToMintForReward);
        require(Token.approve(address(MintReward), amountToMintForReward), "MinterBurner: approve failed");
        MintReward.receiveReward(amountToMintForReward);

        for (uint256 i = 0; i < mintReceivers.length; i++) {
            MintReceiver memory mintReceiver = mintReceivers[i];
            uint256 rAmountToMint = (amountToMint * mintReceiver.deciPercents) / 1000;

            ReceiverBurnAndMint memory rNew = ReceiverBurnAndMint(
                rAmountToMint,
                mintBurnIndex,
                mintReceiver.deciPercents,
                block.timestamp,
                block.number
            );

            uint256 uIndex = receiverBurnAndMintIndex[mintReceiver.receiver] + 1;
            receiverBurnAndMintIndex[mintReceiver.receiver] = uIndex;

            receiverBurnAndMintHistory[mintReceiver.receiver][uIndex] = rNew;

            Token.mint(
                mintReceiver.receiver,
                rAmountToMint
            );
        }

        emit BurntAndMinted(readyToBurn, amountToMint, mintBurnIndex);

        readyToBurn = 0;

        mintBurnIndex++;
    }

    // @notice Increase amount of tokens for spending for maintenance for 'msg.sender'
    // @param value is amount of tokens to increase
    function increaseAmount(uint256 value) external whenNotPaused {
        address account = _msgSender();

        require(value > 0, "MinterBurner: Cannot deposit 0 tokens");

        require(Token.transferFrom(account, address(this), value), "MinterBurner: transferFrom failed");

        toBurnBalances[account] += value;

        emit IncreasedAmount(account, value);

    }

    // @notice Increase amount of tokens for spending for maintenance for '_addr'
    // @param value is amount of tokens to increase
    function increaseAmountFor(address _addr, uint256 value) external whenNotPaused {
        address account = _msgSender();

        require(value > 0, "MinterBurner: Cannot deposit 0 tokens");

        require(Token.transferFrom(account, address(this), value), "MinterBurner: transferFrom failed");

        toBurnBalances[_addr] += value;

        emit IncreasedAmount(_addr, value);

    }

    // @notice Balance of tokens for spending for maintenance for 'account'
    // @param account is address of account
    function balanceOf(address account) public view virtual returns (uint256) {
        return toBurnBalances[account];
    }

    // @notice Spend `amount` tokens for maintenance from 'account'
    // @param account is address of account
    // @param amount is amount of tokens to spend
    function spendForMaintenances(
        address account,
        uint256 amount
    ) external onlyRole(SPENDER_ROLE) nonReentrant whenNotPaused {
        require(
            toBurnBalances[account] >= amount,
            "MinterBurner: not enough balance"
        );
        toBurnBalances[account] -= amount;
        readyToBurn += amount;

        emit SpentBalance(account, amount);
    }

    // @notice Withdraw all tokens for spending for maintenance from 'msg.sender'
    function withdraw() external nonReentrant {
        address account = _msgSender();
        uint256 balance = toBurnBalances[account];
        require(balance > 0, "MinterBurner: nothing to withdraw");

        toBurnBalances[account] = 0;

        require(Token.transfer(_msgSender(), balance), "MinterBurner: transfer failed");

        emit Withdrawn(account, balance);
    }


    // @notice Transfer ownership of ERC20 token to 'newOwner'
    // @param newOwner is address of new owner
    function transferTokenOwnership(address newOwner) external onlyRole(TOKEN_OWNER_ROLE) {
        require(newOwner != address(0), "MinterBurner: new owner is the zero address");

        Token.transferOwnership(newOwner);
    }

    // @notice Mint tokens to '_addr'
    // @param _addr is receiver tokens address
    // @param _amount is amount of tokens
    function mintTokens(address _addr, uint256 _amount) external onlyRole(TOKEN_OWNER_ROLE) {

        Token.mint(_addr, _amount);
    }


    // @notice Burn tokens '_addr'
    // @param _addr is address
    // @param _amount is amount to burn
    function burnTokens(address _addr, uint256 _amount) external onlyRole(TOKEN_OWNER_ROLE) {

        Token.burn(_addr, _amount);
    }

    // @notice Update mintReward contract address '_mintReward'
    // @param _mintReward is a new address
    function updateMintReward(address _mintReward) external onlyRole(CONFIGURATOR_ROLE) {
        require(_mintReward != address(0), "MinterBurner: MintReward is zero address");
        MintReward = IMintReward(_mintReward);
    }

    function _authorizeUpgrade(address newImplementation) internal onlyRole(UPGRADER_ROLE) override {}

}
