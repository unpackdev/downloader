/*

██████╗░██████╗░██╗███╗░░░███╗███████╗██████╗░░█████╗░░█████╗░
██╔══██╗██╔══██╗██║████╗░████║██╔════╝██╔══██╗██╔══██╗██╔══██╗
██████╔╝██████╔╝██║██╔████╔██║█████╗░░██║░░██║███████║██║░░██║
██╔═══╝░██╔══██╗██║██║╚██╔╝██║██╔══╝░░██║░░██║██╔══██║██║░░██║
██║░░░░░██║░░██║██║██║░╚═╝░██║███████╗██████╔╝██║░░██║╚█████╔╝
╚═╝░░░░░╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝╚══════╝╚═════╝░╚═╝░░╚═╝░╚════╝░

*/

// SPDX-License-Identifier: GPL-3.0-or-later
// LBPManager Factory contract. Governance to create new LBPManager contracts.
// Copyright (C) 2021 PrimeDao

// solium-disable linebreak-style
pragma solidity 0.8.9;

import "./CloneFactory.sol";
import "./Ownable.sol";
import "./LBPManager.sol";

/**
 * @title LBPManager Factory
 * @dev   Governance to create new LBPManager contracts.
 */
contract LBPManagerFactory is CloneFactory, Ownable {
    address public masterCopy;
    address public lbpFactory;

    event LBPManagerDeployed(
        address indexed lbpManager,
        address indexed admin,
        bytes metadata
    );

    event LBPFactoryChanged(
        address indexed oldLBPFactory,
        address indexed newLBPFactory
    );

    event MastercopyChanged(
        address indexed oldMasterCopy,
        address indexed newMasterCopy
    );

    /**
     * @dev                             Constructor.
     * @param _lbpFactory               The address of Balancers LBP factory.
     */
    constructor(address _lbpFactory) {
        require(_lbpFactory != address(0), "LBPMFactory: LBPFactory is zero");
        lbpFactory = _lbpFactory;
    }

    modifier validAddress(address addressToCheck) {
        require(addressToCheck != address(0), "LBPMFactory: address is zero");
        // solhint-disable-next-line reason-string
        require(
            addressToCheck != address(this),
            "LBPMFactory: address same as LBPManagerFactory"
        );
        _;
    }

    /**
     * @dev                             Set LBPManager contract which works as a base for clones.
     * @param _masterCopy               The address of the new LBPManager basis.
     */
    function setMasterCopy(address _masterCopy)
        external
        onlyOwner
        validAddress(_masterCopy)
    {
        emit MastercopyChanged(masterCopy, _masterCopy);
        masterCopy = _masterCopy;
    }

    /**
     * @dev                             Set Balancers LBP Factory contract as basis for deploying LBPs.
     * @param _lbpFactory               The address of Balancers LBP factory.
     */
    function setLBPFactory(address _lbpFactory)
        external
        onlyOwner
        validAddress(_lbpFactory)
    {
        emit LBPFactoryChanged(lbpFactory, _lbpFactory);
        lbpFactory = _lbpFactory;
    }

    /**
     * @dev                             Deploy and initialize LBPManager.
     * @param _admin                    The address of the admin of the LBPManager.
     * @param _beneficiary              The address that receives the _fees.
     * @param _name                     Name of the LBP.
     * @param _symbol                   Symbol of the LBP.
     * @param _tokenList                Numerically sorted array (ascending) containing two addresses:
                                            - The address of the project token being distributed.
                                            - The address of the funding token being exchanged for the project token.
     * @param _amounts                  Sorted array to match the _tokenList, containing two parameters:
                                            - The amounts of project token to be added as liquidity to the LBP.
                                            - The amounts of funding token to be added as liquidity to the LBP.
     * @param _startWeights                  Sorted array to match the _tokenList, containing two parametes:
                                            - The start weight for the project token in the LBP.
                                            - The start weight for the funding token in the LBP.
     * @param _startTimeEndtime         Array containing two parameters:
                                            - Start time for the LBP.
                                            - End time for the LBP.
     * @param _endWeights               Sorted array to match the _tokenList, containing two parametes:
                                            - The end weight for the project token in the LBP.
                                            - The end weight for the funding token in the LBP.
     * @param _fees                     Array containing two parameters:
                                            - Percentage of fee paid for every swap in the LBP.
                                            - Percentage of fee paid to the _beneficiary for providing the service of the LBP Manager.
     * @param _metadata                 IPFS Hash of the LBP creation wizard information.
     */
    function deployLBPManager(
        address _admin,
        address _beneficiary,
        string memory _name,
        string memory _symbol,
        IERC20[] memory _tokenList,
        uint256[] memory _amounts,
        uint256[] memory _startWeights,
        uint256[] memory _startTimeEndtime,
        uint256[] memory _endWeights,
        uint256[] memory _fees,
        bytes memory _metadata
    ) external onlyOwner {
        // solhint-disable-next-line reason-string
        require(
            masterCopy != address(0),
            "LBPMFactory: LBPManager mastercopy not set"
        );

        address lbpManager = createClone(masterCopy);

        LBPManager(lbpManager).initializeLBPManager(
            lbpFactory,
            _beneficiary,
            _name,
            _symbol,
            _tokenList,
            _amounts,
            _startWeights,
            _startTimeEndtime,
            _endWeights,
            _fees,
            _metadata
        );

        LBPManager(lbpManager).transferAdminRights(_admin);

        emit LBPManagerDeployed(lbpManager, _admin, _metadata);
    }
}
