// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.19;

import "./Module.sol";
import "./MotivatorV2.sol";
import "./Governor.sol";
import "./IZkSync.sol";
import "./OwnableUpgradeable.sol";

/**
 * @title Relayer
 * @author Federation - https://x.com/FederationWTF
 */
abstract contract Relayer is Module, OwnableUpgradeable, MotivatorV2 {
    /// The proposal has already been relayed to the DAO
    error AlreadyRelayed();
    
    /// The message was not valid
    error InvalidMessageProof();
    
    /// The proposal quorum was not met
    error QuorumNotMet();

    /**
     * @notice The proposal has been relayed to the DAO
     * @param proposal The proposal id
     * @param support The vote support
     * @param totalVotes The total number of votes
     * @param totalVotesCast The total number of votes cast
    */
    event VotesRelayed(
        uint256 indexed proposal, 
        uint8 support, 
        uint256 totalVotes, 
        uint256 totalVotesCast
    );
    
    /**
     * @notice The relayer config has changed
     * @param config The new config
    */
    event ConfigChanged(Config config);

    struct Config {
        /// Address of the base wallet
        address base;
        /// Address of the DAO we are casting votes against
        address externalDAO;
        /// Address of the token representing the votes
        address nativeToken;
        /// Address of the zkSync contract
        address zkSync;
        /// Address of the governor
        address governor;
        /// The BPS number of votes required to pass a proposal
        uint256 quorumVotesBPS;
    }
    
    struct Proposal {
        /// The proposal id
        uint256 id;
        /// The proposal for votes
        uint256 forVotes;
        /// The proposal against votes
        uint256 againstVotes;
        /// The proposal abstain votes
        uint256 abstainVotes;
    }

    /// The config for the contract
    Config public config;

    /**
     * @notice Change the contract config
     * @param _config The new contract config
     */
    function setConfig(Config calldata _config) external onlyOwner {
        config = _config;
        emit ConfigChanged(_config);
    }

    function setGovernorConfig(Governor.Config calldata _config, uint256 _gasLimit, uint256 _gasPerPubdataByteLimit) external payable onlyOwner {
        IZkSync zksync = IZkSync(config.zkSync);

        zksync.requestL2Transaction{value: msg.value}(config.governor, 0, abi.encodeWithSelector(
            Governor.setConfig.selector,
            _config
        ), _gasLimit, _gasPerPubdataByteLimit, new bytes[](0), msg.sender);
    }

    /**
     * @notice Changes the motivator config
     * @param _motivatorConfig The new config
    */
    function setMotivatorConfig(MotivatorConfig calldata _motivatorConfig) external onlyOwner  {
        _setMotivatorConfig(_motivatorConfig);
    }

    function setGovernorMotivatorConfig(MotivatorConfig calldata _motivatorConfig, uint256 _gasLimit, uint256 _gasPerPubdataByteLimit) external payable onlyOwner {
        IZkSync zksync = IZkSync(config.zkSync);

        zksync.requestL2Transaction{value: msg.value}(config.governor, 0, abi.encodeWithSelector(
            Governor.setMotivatorConfig.selector,
            _motivatorConfig
        ), _gasLimit, _gasPerPubdataByteLimit, new bytes[](0), msg.sender);
    }

    /**
     * @notice Withdraw funds stored in the contract
     * @param _amount The amount to withdraw
     * @param _to The address to withdraw to
    */
    function withdraw(uint256 _amount, address _to) external onlyOwner {
        _withdraw(_amount, _to);
    }

    function withdrawFromGovenor(uint256 _amount, address _to, uint256 _gasLimit, uint256 _gasPerPubdataByteLimit) external payable onlyOwner {
        IZkSync zksync = IZkSync(config.zkSync);

        zksync.requestL2Transaction{value: msg.value}(config.governor, 0, abi.encodeWithSelector(
            Governor.withdraw.selector,
            _amount,
            _to
        ), _gasLimit, _gasPerPubdataByteLimit, new bytes[](0), msg.sender);
    }
}

