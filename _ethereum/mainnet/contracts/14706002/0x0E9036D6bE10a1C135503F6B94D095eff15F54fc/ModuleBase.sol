// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./IDaoDepositManager.sol";
import "./IDealManager.sol";

/**
 * @title                   PrimeDeals Module Base
 * @notice                  Smart contract to serve as the
                            basis for each module
 */
contract ModuleBase {
    /// Address of the DealManager implementation
    IDealManager public immutable dealManager;

    /**
     * @notice              Constructor
     * @param _dealManager  The address of DealManager implementation
     */
    constructor(address _dealManager) {
        require(_dealManager != address(0), "ModuleBase: Error 100");
        dealManager = IDealManager(_dealManager);
    }

    /**
      * @notice             Sends tokens from a DAO deposit manager to the module
      * @param _dealId      ID of the action this is related to
      * @param _daos        Array containing the DAOs that are involed in this action
      * @param _tokens      Array containing the tokens that are involed in this action
      * @param _path        Double nested array containing the amounts of tokens for each
                            token for each dao to be send
      * @return amountsIn   Array containing the total amounts sent per token
    */
    function _pullTokensIntoModule(
        uint32 _dealId,
        address[] memory _daos,
        address[] memory _tokens,
        uint256[][] memory _path
    ) internal returns (uint256[] memory amountsIn) {
        amountsIn = new uint256[](_tokens.length);
        require(_path.length == _tokens.length, "ModuleBase: Error 102");
        uint256 tokenArrayLength = _tokens.length;
        for (uint256 i; i < tokenArrayLength; ++i) {
            uint256[] memory tokenPath = _path[i];
            require(tokenPath.length == _daos.length, "ModuleBase: Error 102");
            uint256 tokenPathArrayLength = tokenPath.length;
            for (uint256 j; j < tokenPathArrayLength; ++j) {
                uint256 daoAmount = tokenPath[j];
                if (daoAmount > 0) {
                    amountsIn[i] += daoAmount;
                    IDaoDepositManager(
                        dealManager.getDaoDepositManager(_daos[j])
                    ).sendToModule(_dealId, _tokens[i], daoAmount);
                }
            }
        }
    }

    /**
     * @notice              Calls the approval function of a token
     * @param _token        Address of the token
     * @param _to           Target of the approval
     * @param _amount       Amount to be approved
     */
    function _approveToken(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        require(IERC20(_token).approve(_to, _amount), "ModuleBase: Error 243");
    }

    /**
     * @notice              Calls the approval function of a token
                            for the deposit manager of a DAO
     * @param _token        Address of the token
     * @param _dao          DAO whose deposit manager is the target
     * @param _amount       Amount to be approved
     */
    function _approveDaoDepositManager(
        address _token,
        address _dao,
        uint256 _amount
    ) internal {
        _approveToken(_token, dealManager.getDaoDepositManager(_dao), _amount);
    }

    /**
     * @notice              Transfers an amount of tokens
     * @param _token        Address of the token
     * @param _to           Target of the transfer
     * @param _amount       Amount to be sent
     */
    function _transfer(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        if (_token != address(0)) {
            try IERC20(_token).transfer(_to, _amount) returns (bool success) {
                require(success, "ModuleBase: Error 241");
            } catch {
                revert("ModuleBase: Error 241");
            }
        } else {
            // solhint-disable-next-line avoid-low-level-calls
            (bool sent, ) = _to.call{value: _amount}("");
            require(sent, "ModuleBase: Error 242");
        }
    }

    /**
     * @notice              Transfers an amount of tokens from an address
     * @param _token        Address of the token
     * @param _from         Source of the transfer
     * @param _to           Target of the transfer
     * @param _amount       Amount to be sent
     */
    function _transferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        require(_token != address(0), "ModuleBase: Error 263");

        try IERC20(_token).transferFrom(_from, _to, _amount) returns (
            bool success
        ) {
            require(success, "ModuleBase: Error 241");
        } catch {
            revert("ModuleBase: Error 241");
        }
    }

    /**
     * @notice              Checks if the deal has been expired
     * @param _dealId       The dealId of the action (position in the array)
     * @return bool         A bool flag indiciating whether deal has expired
     */
    function hasDealExpired(uint32 _dealId)
        public
        view
        virtual
        returns (bool)
    // solhint-disable-next-line no-empty-blocks
    {

    }
}
