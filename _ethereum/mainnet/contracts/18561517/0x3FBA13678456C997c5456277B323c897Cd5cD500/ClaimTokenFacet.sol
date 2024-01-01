// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./LibClaimTokenStorage.sol";
import "./LibAppStorage.sol";
import "./LibMeta.sol";

contract ClaimTokenFacet is Modifiers {
    /** external functions of the Gov Protocol Contract */
    /**
    @dev function to add token to approvedTokens mapping
    *@param _claimTokenAddress of the new claim token Address
    *@param _claimtokendata struct of the _claimTokenAddress
    */
    function addClaimToken(
        address _claimTokenAddress,
        LibClaimTokenStorage.ClaimTokenData memory _claimtokendata
    )
        external
        onlySuperAdmin(
            LibMeta._msgSender()
        ) /** only super admin wallet can add sun tokens */
    {
        LibClaimTokenStorage.ClaimStorage storage es = LibClaimTokenStorage
            .claimTokenStorage();

        require(_claimTokenAddress != address(0), "GCL: null address error");
        require(
            _claimtokendata.pegOrSunTokens.length <= LibAppStorage.arrayMaxSize,
            "GCL: array size exceed"
        );
        require(
            _claimtokendata.pegOrSunTokens.length ==
                _claimtokendata.pegOrSunTokensPricePercentage.length,
            "GCL: length mismatch"
        );

        require(
            _claimtokendata.dexRouter != address(0),
            "dex address zero not allowed"
        );

        require(
            !es.approvedClaimTokens[_claimTokenAddress],
            "GCL: already approved"
        );

        es.approvedClaimTokens[_claimTokenAddress] = true;
        es.claimTokens[_claimTokenAddress] = _claimtokendata;
        for (uint256 i = 0; i < _claimtokendata.pegOrSunTokens.length; i++) {
            require(
                _claimtokendata.pegOrSunTokens[i] != address(0),
                "GCL: null address error"
            );
            require(
                es.claimTokenofSUN[_claimtokendata.pegOrSunTokens[i]] ==
                    address(0),
                "GCL: sun token already assigned to a claim token"
            );
            es.claimTokenofSUN[
                _claimtokendata.pegOrSunTokens[i]
            ] = _claimTokenAddress;
        }

        emit LibClaimTokenStorage.ClaimTokenAdded(
            _claimTokenAddress,
            _claimtokendata.tokenType,
            _claimtokendata.pegOrSunTokens,
            _claimtokendata.pegOrSunTokensPricePercentage,
            _claimtokendata.dexRouter
        );
    }

    /**
     @dev function to update the token market data
     *@param _claimTokenAddress to check if it exit in the array and mapping
     *@param _newClaimtokendata struct to update the token market
     */
    function updateClaimToken(
        address _claimTokenAddress,
        LibClaimTokenStorage.ClaimTokenData memory _newClaimtokendata
    )
        external
        onlySuperAdmin(
            LibMeta._msgSender()
        ) /** only super admin wallet can add sun tokens */
    {
        LibClaimTokenStorage.ClaimStorage storage es = LibClaimTokenStorage
            .claimTokenStorage();
        LibClaimTokenStorage.ClaimTokenData storage claimTokenData = es
            .claimTokens[_claimTokenAddress];
        require(
            es.approvedClaimTokens[_claimTokenAddress],
            "GCL: claim token not approved"
        );

        require(
            claimTokenData.pegOrSunTokens.length +
                _newClaimtokendata.pegOrSunTokens.length <=
                LibAppStorage.arrayMaxSize,
            "GCL: array size exceed"
        );
        require(
            _newClaimtokendata.pegOrSunTokens.length ==
                _newClaimtokendata.pegOrSunTokensPricePercentage.length,
            "GCL: length mismatch"
        );

        for (uint256 i = 0; i < _newClaimtokendata.pegOrSunTokens.length; i++) {
            require(
                _newClaimtokendata.pegOrSunTokens[i] != address(0),
                "GCL: null address error"
            );
            require(
                es.claimTokenofSUN[_newClaimtokendata.pegOrSunTokens[i]] ==
                    address(0),
                "GCL: sun token already assigned to a claim token"
            );
            claimTokenData.pegOrSunTokens.push(
                _newClaimtokendata.pegOrSunTokens[i]
            );
            claimTokenData.pegOrSunTokensPricePercentage.push(
                _newClaimtokendata.pegOrSunTokensPricePercentage[i]
            );

            es.claimTokenofSUN[
                _newClaimtokendata.pegOrSunTokens[i]
            ] = _claimTokenAddress;
        }

        claimTokenData.tokenType = _newClaimtokendata.tokenType;
        claimTokenData.dexRouter = _newClaimtokendata.dexRouter;

        emit LibClaimTokenStorage.ClaimTokenUpdated(
            _claimTokenAddress,
            _newClaimtokendata.tokenType,
            _newClaimtokendata.pegOrSunTokens,
            _newClaimtokendata.pegOrSunTokensPricePercentage,
            _newClaimtokendata.dexRouter
        );
    }

    /**
     *@dev function to make claim token enable or disable
     *@param _claimTokenAddress address of the claim token
     *@param _status to enable or disable
     */
    function enableClaimToken(
        address _claimTokenAddress,
        bool _status
    ) external onlySuperAdmin(LibMeta._msgSender()) {
        LibClaimTokenStorage.ClaimStorage storage es = LibClaimTokenStorage
            .claimTokenStorage();
        require(
            es.approvedClaimTokens[_claimTokenAddress] != _status,
            "GCL: already in desired state"
        );
        es.approvedClaimTokens[_claimTokenAddress] = _status;
        emit LibClaimTokenStorage.ClaimTokenEnabled(
            _claimTokenAddress,
            _status
        );
    }

    function isClaimToken(
        address _claimTokenAddress
    ) external view returns (bool) {
        LibClaimTokenStorage.ClaimStorage storage es = LibClaimTokenStorage
            .claimTokenStorage();
        return es.approvedClaimTokens[_claimTokenAddress];
    }

    /// @dev get the ClaimToken address of the sunToken
    function getClaimTokenofSUNToken(
        address _sunToken
    ) external view returns (address) {
        LibClaimTokenStorage.ClaimStorage storage es = LibClaimTokenStorage
            .claimTokenStorage();
        return es.claimTokenofSUN[_sunToken];
    }

    /// @dev get the claimToken struct ClaimTokenData
    function getClaimTokensData(
        address _claimTokenAddress
    ) external view returns (LibClaimTokenStorage.ClaimTokenData memory) {
        LibClaimTokenStorage.ClaimStorage storage es = LibClaimTokenStorage
            .claimTokenStorage();
        return es.claimTokens[_claimTokenAddress];
    }
}
