// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {TransferHelper}             from "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import {FixedPointMathLib}          from "@rari-capital/solmate/src/utils/FixedPointMathLib.sol";

import {Initializable}              from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable}   from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {PausableUpgradeable}        from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {IERC20Upgradeable}          from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IERC20Permit}               from "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

import {BondPriceLib}               from "./libraries/BondPriceLib.sol";
import {AccrualBondLib}             from "./libraries/AccrualBondLib.sol";

import {AccrualBondStorageV1}       from "./AccrualBondStorageV1.sol";

interface ICNV {
    function mint(address guy, uint256 wad) external;
    function burn(address guy, uint256 wad) external;
}

contract AccrualBondsV1 is AccrualBondStorageV1, Initializable, AccessControlUpgradeable, PausableUpgradeable {

    /* -------------------------------------------------------------------------- */
    /*                           ACCESS CONTROL ROLES                             */
    /* -------------------------------------------------------------------------- */

    bytes32 public constant TREASURY_ROLE           = DEFAULT_ADMIN_ROLE;
    bytes32 public constant STAKING_ROLE            = bytes32(keccak256("STAKING_ROLE"));
    bytes32 public constant POLICY_ROLE             = bytes32(keccak256("POLICY_ROLE"));

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */

    /// @notice emitted when a bond is sold/purchased
    /// @param bonder account that purchased the bond
    /// @param token token used to purchase the bond 
    /// @param output amount of output tokens obligated to user
    event BondSold(
        address indexed bonder, 
        address indexed token, 
        uint256 input, 
        uint256 output
    );

    /// @notice emitted when a bond is redeemed/claimed
    /// @param bonder account that purchased the bond
    /// @param bondId users bond position identifier 
    /// @param output amount of output tokens obligated to user
    event BondRedeemed(
        address indexed bonder, 
        uint256 indexed bondId, 
        uint256 output
    );

    /// @notice emitted when a user transfers a bond to another account
    /// @param sender the account that is transfering a bond
    /// @param recipient the account that is receiving the bond
    event BondTransfered(
        address indexed sender,
        address indexed recipient,
        uint256 senderBondId,
        uint256 recipientBondId
    );

    /// @notice emitted when policy updates pricing or mints supply
    /// @param caller presumably policy multi-sig
    /// @param supplyDelta the amount of output tokens to mint to this contract
    /// @param positiveDelta whether the supply delta is postive or negative (mint or burn)
    /// @param newVirtualOutputReserves the new value for virtual output reserves
    /// @param tokens the quote assets that will have their pricing info updated
    /// @param virtualInputReserves the new virtualInputReserves for tokens, used in pricing
    /// @param halfLives the new halfLives for tokens, used in pricing
    /// @param levelBips the new levelBips for tokens, used in pricing
    /// @param updateElapsed whether tokens elapsed time should be updated, used in pricing
    event PolicyUpdate(
        address indexed caller, 
        uint256 supplyDelta, 
        bool indexed positiveDelta,
        uint256 newVirtualOutputReserves, 
        address[] tokens, 
        uint256[] virtualInputReserves, 
        uint256[] halfLives, 
        uint256[] levelBips, 
        bool[] updateElapsed
    );

    /// @notice emitted when quote asset is added
    /// @param caller presumably treasury multi-sig
    /// @param token token used to purchase the bond 
    /// @param virtualInputReserves virtual reserves for input token
    /// @param halfLife rate of change for decay/growth mechanism
    /// @param levelBips percentage of current virtual reserves to target 
    event InputAssetAdded(
        address indexed caller, 
        address indexed token, 
        uint256 virtualInputReserves, 
        uint256 halfLife, 
        uint256 levelBips
    );

    /// @notice emitted when quote asset is removed
    /// @param caller presumably policy or treasury multi-sig
    /// @param token token used to purchase the bond 
    event InputAssetRemoved(
        address indexed caller,
        address indexed token
    );

    /// @notice emitted when policy mint allowance is updated
    /// @param caller presumably policy multi-sig
    event PolicyMintAllowanceSet(
        address indexed caller, 
        uint256 mintAllowance
    );

    /// @notice emitted when revenue beneficiary is set
    /// @param caller presumably the treasury multi-sig
    /// @param beneficiary new account that will receive accrued funds
    event BeneficiarySet(
        address indexed caller, 
        address beneficiary
    );

    /// @notice emitted when staking vebases
    /// @param outputTokensEmitted the amount of output tokens emitted this epoch
    event Vebase(
        uint256 outputTokensEmitted
    );

    /* -------------------------------------------------------------------------- */
    /*                               INITIALIZATION                               */
    /* -------------------------------------------------------------------------- */

    /// @notice OZ upgradeable initialization
    function initialize(
        uint256 _term,
        uint256 _virtualOutputReserves,
        address _outputToken,
        address _beneficiary,
        address _treasury,
        address _policy,
        address _staking
    ) external virtual initializer {
        // make sure contract has not been initialized
        require(term == 0, "INITIALIZED");

        // initialize state
        __Context_init();
        __AccessControl_init();
        __Pausable_init();
        __ERC165_init();

        term = _term;
        virtualOutputReserves = _virtualOutputReserves;
        outputToken = _outputToken;
        beneficiary = _beneficiary;

        // setup roles
        _grantRole(DEFAULT_ADMIN_ROLE, _treasury);
        _grantRole(POLICY_ROLE, _policy);
        _grantRole(STAKING_ROLE, _staking);

        // pause contract
        _pause();
    }



    /* -------------------------------------------------------------------------- */
    /*                             PURCHASE BOND LOGIC                            */
    /* -------------------------------------------------------------------------- */

    /// @notice internal logic that handles bond purchases
    /// @param sender the account that purchased the bond
    /// @param recipient the account that will receive the bond
    /// @param token token used to purchase the bond 
    /// @param input the amount of input tokens used to purchase bond
    /// @param minOutput the min amount of output tokens bonder is willig to receive
    function _purchaseBond(
        address sender,
        address recipient,
        address token,
        uint256 input,
        uint256 minOutput
    ) internal whenNotPaused() virtual returns (uint256 output) {

        // F6: CHECKS
        
        // fetch quote price info from storage
        BondPriceLib.QuotePriceInfo storage quote = quoteInfo[token];
        
        // make sure there is pricing info for token
        require(quote.virtualInputReserves != 0,"!LIQUIDITY");
        
        // calculate and store availableDebt so we can ensure
        // we're not incuring more debt than we can pay back
        uint256 availableDebt = IERC20Upgradeable(outputToken).balanceOf(address(this)) - totalDebt;
        
        // calculate 'output' value
        output = BondPriceLib.getAmountOut(
            input,
            availableDebt,
            virtualOutputReserves,
            quote.virtualInputReserves,
            block.timestamp - quote.lastUpdate,
            quote.halfLife,
            quote.levelBips
        );
        
        // if output is less than min output, or greater than available debt revert
        require(output >= minOutput && availableDebt >= output, "!output");

        // F6: EFFECTS

        // transfer principal from sender -> beneficiary
        TransferHelper.safeTransferFrom(token, sender, beneficiary, input);
        
        // unchecked because cnvEmitted and totalDebt cannot
        // be greater than totalSupply, which is checked 
        unchecked { 
            // increase cnvEmitted by amount sold
            cnvEmitted += output;

            // increase totalDebt by amount sold
            totalDebt += output;
        }

        quote.virtualInputReserves += input;
        
        // push position to user storage
        positions[recipient].push(AccrualBondLib.Position(output, 0, block.timestamp));
      
        // T2 - Are events emitted for every storage mutating function?
        emit BondSold(sender, token, input, output);
    }

    /// @notice purchase an accrual bond
    /// @param recipient the account that will receive the bond
    /// @param token token used to purchase the bond 
    /// @param input the amount of input tokens used to purchase bond
    /// @param minOutput the min amount of output tokens bonder is willig to receive
    function purchaseBond(
        address recipient,
        address token,
        uint256 input,
        uint256 minOutput
    ) external virtual returns (uint256 output) {
        
        // purchase bond on behalf of recipient
        return _purchaseBond(msg.sender, recipient, token, input, minOutput);
    }

    /// @notice purchase an accrual bond using EIP-2612 permit
    /// @param recipient the account that will receive the bond
    /// @param token token used to purchase the bond 
    /// @param input the amount of input tokens used to purchase bond
    /// @param minOutput the min amount of output tokens bonder is willig to receive
    /// @param deadline eip-2612
    /// @param v eip-2612
    /// @param r eip-2612     
    /// @param s eip-2612
    function purchaseBondUsingPermit(
        address recipient,
        address token,
        uint256 input,
        uint256 minOutput,
        uint256 deadline, uint8 v, bytes32 r, bytes32 s
    ) external virtual returns (uint256 output) {
        
        // approve tokens for spender - https://eips.ethereum.org/EIPS/eip-2612
        IERC20Permit(token).permit(msg.sender, address(this), input, deadline, v, r, s);

        // purchase bond on behalf of recipient
        return _purchaseBond(msg.sender, recipient, token, input, minOutput);
    }

    /* -------------------------------------------------------------------------- */
    /*                              REDEEM BOND LOGIC                             */
    /* -------------------------------------------------------------------------- */

    /// @notice redeem your bond with output distrobuted linearly
    /// @param recipient the account that will receive the bond
    /// @param bondId users bond position identifier 
    function redeemBond(
        address recipient,
        uint256 bondId
    ) external whenNotPaused() virtual returns (uint256 output) {

        // F6: CHECKS

        // fetch position from storage
        AccrualBondLib.Position storage position = positions[msg.sender][bondId];
        
        // calculate redemption amount
        output = AccrualBondLib.getRedeemAmountOut(position.owed, position.redeemed, position.creation, term);
        
        // skip redemption if output is zero to save gas
        if (output > 0) {

            // F6: EFFECTS
            
            // decrease total debt by redeemed amount
            totalDebt -= output;
            
            // increase user redeemed amount by redeemed amount
            position.redeemed += output;
            
            // send recipient redeemed output tokens
            TransferHelper.safeTransfer(outputToken, recipient, output);
            
            // T2 - Are events emitted for every storage mutating function?
            emit BondRedeemed(msg.sender, bondId, output);
        }

        // revert is output is equal to zero to save gas 
        require(output > 0, "!output");
    }

    /// @notice redeem your bond with output distrobuted linearly
    /// @param recipient the account that will receive the bond
    /// @param bondIds array of users bond position identifiers
    function redeemBondBatch(
        address recipient,
        uint256[] memory bondIds
    ) external whenNotPaused() virtual returns (uint256 totalOutput) {

        // cache array length to save gas
        uint256 length = bondIds.length;

        // redeem users bonds
        for (uint256 i; i < length;) {

            // fetch position from storage
            AccrualBondLib.Position storage position = positions[msg.sender][bondIds[i]];
            
            // calculate redemption amount
            uint256 output = AccrualBondLib.getRedeemAmountOut(position.owed, position.redeemed, position.creation, term);
            
            // increase user redeemed amount by redeemed amount
            position.redeemed += output;

            // increase totalOutput by this bonds output
            totalOutput += output;

            // T2 - Are events emitted for every storage mutating function?
            emit BondRedeemed(msg.sender, bondIds[i], output);

            // increment loop index
            unchecked { i++; }
        }

        // decrease total debt by total redeemed amount
        totalDebt -= totalOutput;
        
        // send recipient total redeemed output
        TransferHelper.safeTransfer(outputToken, recipient, totalOutput);
    }

    /* -------------------------------------------------------------------------- */
    /*                            BOND TRANSFER LOGIC                             */
    /* -------------------------------------------------------------------------- */

    /// @notice transfer a bond from one account to another
    /// @param recipient the account that will receive the bond
    /// @param bondId users bond position identifier 
    function transferBond(
        address recipient,
        uint256 bondId
    ) external whenNotPaused() virtual {

        // cache position info from storage
        AccrualBondLib.Position memory position = positions[msg.sender][bondId];

        // delete position from senders storage
        delete positions[msg.sender][bondId];

        // push position to recipients storage
        positions[recipient].push(position);

        // T2 - Are events emitted for every storage mutating function?
        emit BondTransfered(msg.sender, recipient, bondId, positions[recipient].length);
    }

    /* -------------------------------------------------------------------------- */
    /*                              MANAGEMENT LOGIC                              */
    /* -------------------------------------------------------------------------- */

    /// @notice update pricing + mint supply if policy and there's sufficient mint allowance
    /// @param supplyDelta the amount of output tokens to mint to this contract
    /// @param positiveDelta whether the supply delta is postive or negative (mint or burn)
    /// @param newVirtualOutputReserves the new value for virtual output reserves
    /// @param tokens the quote assets that will have their pricing info updated
    /// @param virtualInputReserves the new virtualInputReserves for tokens, used in pricing
    /// @param halfLives the new halfLives for tokens, used in pricing
    /// @param levelBips the new levelBips for tokens, used in pricing
    /// @param updateElapsed whether tokens elapsed time should be updated, used in pricing
    function policyUpdate(
        uint256 supplyDelta,
        bool positiveDelta,
        uint256 newVirtualOutputReserves,
        address[] memory tokens,
        uint256[] memory virtualInputReserves,
        uint256[] memory halfLives,
        uint256[] memory levelBips,
        bool[] memory updateElapsed
    ) external virtual onlyRole(POLICY_ROLE) {

        // CHECK THAT WE SUFFICE STAKING.minPrice()

        // if supplyDelta is greater than zero, mint supply
        if (supplyDelta > 0) {

            if (positiveDelta) {
                // F6: CHECKS 

                // decrease policy allowance by mint amount
                // reverts if supplyDelta is greater
                policyMintAllowance -= supplyDelta;

                // F6: EFFECTS

                // mint output tokens to this contract
                ICNV(outputToken).mint(address(this), supplyDelta);
            } else {
                // F6: CHECKS 

                // check that policy is not burning more than available debt
                require(
                    IERC20Upgradeable(outputToken).balanceOf(address(this)) - totalDebt >= supplyDelta, 
                    "!supplyDelta"
                );

                // increase policy allowance by mint amount
                // reverts if supplyDelta is greater
                policyMintAllowance += supplyDelta;

                // F6: EFFECTS

                // mint output tokens to this contract
                ICNV(outputToken).burn(address(this), supplyDelta);
            }
        }

        // if newVirtualOutputReserves is greater than zero update virtual output reserves
        if (newVirtualOutputReserves > 0) virtualOutputReserves = newVirtualOutputReserves;

        // store array length in memory to save gas
        uint256 length = tokens.length;

        // if tokens length is greater than zero batch update quote pricing
        if (length > 0) {

            // make sure all param lengths match
            require(
                length == virtualInputReserves.length &&
                length == halfLives.length       &&
                length == levelBips.length,
                "!LENGTH"
            );

            for (uint256 i; i < length; ) {

                // make sure halfLives are greater than zero
                require(halfLives[i] > 0, "!halfLife");

                // update quote pricing info for each index
                quoteInfo[tokens[i]] = BondPriceLib.QuotePriceInfo(
                    virtualInputReserves[i],
                    updateElapsed[i] ? block.timestamp : quoteInfo[tokens[i]].lastUpdate,
                    halfLives[i],
                    levelBips[i]
                );

                // increment i using unchecked statement to save gas, cannot reasonably overflow
                unchecked { ++i; }
            }
        }

        // T2 - Are events emitted for every storage mutating function?
        emit PolicyUpdate(
            msg.sender, 
            supplyDelta,
            positiveDelta, 
            newVirtualOutputReserves, 
            tokens, 
            virtualInputReserves, 
            halfLives, 
            levelBips, 
            updateElapsed
        );
    }

    /// @notice add quote asset and update quote pricing info
    /// @param token token used to purchase the bond
    /// @param virtualInputReserves virtual reserves for input token
    /// @param halfLife rate of change for decay/growth mechanism
    /// @param levelBips percentage of current virtual reserves to target 
    function addQuoteAsset(
        address token,
        uint256 virtualInputReserves,
        uint256 halfLife,
        uint256 levelBips
    ) external virtual onlyRole(TREASURY_ROLE) {

        // make sure pricing info for this asset does not already exist
        require(quoteInfo[token].lastUpdate == 0, "!EXISTENT");

        // increment totalAssets to account for newly added input token
        unchecked { ++totalAssets; }

        // update pricing info for added asset
        quoteInfo[token] = BondPriceLib.QuotePriceInfo(
            virtualInputReserves,
            block.timestamp,
            halfLife,
            levelBips
        );

        // T2 - Are events emitted for every storage mutating function?
        emit InputAssetAdded(msg.sender, token, virtualInputReserves, halfLife, levelBips);
    }

    /// @notice remove a quote asset
    /// @param token token used to purchase the bond
    function removeQuoteAsset(
        address token
    ) external virtual {

        // make sure caller has either policy role or treasury role
        require(hasRole(POLICY_ROLE, msg.sender) || hasRole(TREASURY_ROLE, msg.sender));

        // fetch quote pricing info from storage
        BondPriceLib.QuotePriceInfo memory quote = quoteInfo[token];

        // make sure quote pricing info doesn't already exist for this token
        require(quote.lastUpdate != 0, "!NONEXISTENT");

        // decrement total assets to account for removed asset
        --totalAssets;

        // delete quote pricing info for removed token 
        delete quoteInfo[token];

        // T2 - Are events emitted for every storage mutating function?
        emit InputAssetRemoved(msg.sender, token);
    }

    /// @notice update policy output token mint allowance if treasury
    /// @param mintAllowance the amount policy is allowed to mint until next update
    function setPolicyMintAllowance(
        uint256 mintAllowance
    ) external virtual onlyRole(TREASURY_ROLE) {

        // update policy mint allowance
        policyMintAllowance = mintAllowance;

        // T2 - Are events emitted for every storage mutating function?
        emit PolicyMintAllowanceSet(msg.sender, mintAllowance);
    }

    /// @notice update the beneficiary address if treasury
    /// @param accrualTo account that receives accrued revenue
    function setBeneficiary(
        address accrualTo
    ) external virtual onlyRole(TREASURY_ROLE) {
        
        // update beneficiary account
        beneficiary = accrualTo;
        
        // T2 - Are events emitted for every storage mutating function?
        emit BeneficiarySet(msg.sender, accrualTo);
    }

    /// @notice pause contract interactions if policy or treasury
    function pause() external virtual {
        
        // make sure caller has either policy role or treasury role
        require(hasRole(POLICY_ROLE, msg.sender) || hasRole(TREASURY_ROLE, msg.sender));
        
        _pause();
    }

    /// @notice unpause contract interactions if policy or treasury
    function unpause() external virtual {

        // make sure caller has either policy role or treasury role
        require(hasRole(POLICY_ROLE, msg.sender) || hasRole(TREASURY_ROLE, msg.sender));
        
        _unpause();
    }

    /* -------------------------------------------------------------------------- */
    /*                                VEBASE LOGIC                                */
    /* -------------------------------------------------------------------------- */

    function vebase() external virtual onlyRole(STAKING_ROLE) returns (bool) {

        // T2 - Are events emitted for every storage mutating function?
        emit Vebase(cnvEmitted);

        // reset/delete cnvEmitted
        delete cnvEmitted;

        // return true
        return true;
    }

    /* -------------------------------------------------------------------------- */
    /*                             PRICE HELPER LOGIC                             */
    /* -------------------------------------------------------------------------- */

    function getVirtualInputReserves(
        address token
    ) external virtual view returns (uint256) {
        // fetch quote pricing info from storage
        BondPriceLib.QuotePriceInfo memory quote = quoteInfo[token];

        // decay virtual reserves
        return BondPriceLib.expToLevel(
            quote.virtualInputReserves, 
            block.timestamp - quote.lastUpdate, 
            quote.halfLife, 
            quote.levelBips
        );
    }

    function getUserPositionCount(
        address account
    ) external virtual view returns (uint256) {
        return positions[account].length;
    }

    function getAvailableSupply() external virtual view returns (uint256) {
        return IERC20Upgradeable(outputToken).balanceOf(address(this)) - totalDebt;
    }

    function getSpotPrice(
        address token
    ) external virtual view returns (uint256) {

        // fetch quote pricing info from storage
        BondPriceLib.QuotePriceInfo memory quote = quoteInfo[token];

        // decay virtual reserves
        uint256 virtualInputReserves = BondPriceLib.expToLevel(
            quote.virtualInputReserves, 
            block.timestamp - quote.lastUpdate, 
            quote.halfLife, 
            quote.levelBips
        );

        // 1 * virtual input token reserves / (availableDebt + virtual output token reserves)
        return FixedPointMathLib.fmul(
            1e18,
            virtualInputReserves,
            IERC20Upgradeable(outputToken).balanceOf(address(this)) - totalDebt + virtualOutputReserves
        );
    }

    function getAmountOut(
        address token,
        uint256 input
    ) external virtual view returns (uint256 output) {

        // fetch quote pricing info from storage
        BondPriceLib.QuotePriceInfo memory quote = quoteInfo[token];

        // calculate available debt, the max amount of output tokens we can distrobute
        uint256 availableDebt = IERC20Upgradeable(outputToken).balanceOf(address(this)) - totalDebt;

        // calculate amount out
        output = BondPriceLib.getAmountOut(
            input,
            availableDebt,
            virtualOutputReserves,
            quote.virtualInputReserves,
            block.timestamp - quote.lastUpdate,
            quote.halfLife,
            quote.levelBips
        );
    }
}