pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

import "./Address.sol";
import "./Ownable.sol";
import "./ISapphireCreditScore.sol";
import "./SapphireTypes.sol";
import "./IDefiPassport.sol";

contract DefiPassportClaimer is Ownable {

    /* ========== Libraries ========== */

    using Address for address;

    /* ========== Events ========== */

    event CreditScoreContractSet(address _newContractAddress);

    event DefiPassportContractSet(address _newDefiPassportContract);

    /* ========== Public variables ========== */

    ISapphireCreditScore public creditScoreContract;

    IDefiPassport public defiPassport;

    /* ========== Constructor ========== */

    constructor(
        address _creditScoreContract,
        address _defiPassportContract
    )
        public
    {
        _setCreditScoreContract(_creditScoreContract);
        _setDefiPassportContract(_defiPassportContract);
    }

    /* ========== Restricted functions ========== */

    function setCreditScoreContract(
        address _creditScoreContract
    )
        external
        onlyOwner
    {
        _setCreditScoreContract(_creditScoreContract);
    }

    /* ========== Public functions ========== */

    /**
     * @notice Mints a passport to the user specified in the score proof
     *
     * @param _scoreProof The credit score proof of the receiver of the passport
     * @param _passportSkin The skin address of the passport
     * @param _skinId The ID of the skin NFT
     */
    function claimPassport(
        SapphireTypes.ScoreProof calldata _scoreProof,
        address _passportSkin,
        uint256 _skinId
    )
        external
    {
        creditScoreContract.verifyAndUpdate(_scoreProof);
        defiPassport.mint(
            _scoreProof.account,
            _passportSkin,
            _skinId
        );
    }

    /* ========== Private functions ========== */

    function _setCreditScoreContract(
        address _creditScoreContract
    )
        private
    {
        require(
            _creditScoreContract.isContract(),
            "DefiPassportClaimer: credit score address is not a contract"
        );

        require(
            address(creditScoreContract) != _creditScoreContract,
            "DefiPassportClaimer: cannot set the same contract address"
        );

        creditScoreContract = ISapphireCreditScore(_creditScoreContract);

        emit CreditScoreContractSet(_creditScoreContract);
    }

    function _setDefiPassportContract(
        address _defiPassportContract
    )
        private
    {
        require(
            _defiPassportContract.isContract(),
            "DefiPassportClaimer: defi passport address is not a contract"
        );

        require(
            address(defiPassport) != _defiPassportContract,
            "DefiPassportClaimer: cannot set the same contract address"
        );

        defiPassport = IDefiPassport(_defiPassportContract);

        emit DefiPassportContractSet(_defiPassportContract);
    }

}
