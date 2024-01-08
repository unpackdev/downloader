//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.0;

interface IDeTrust {

    struct Trust {
        uint id;  // the id of the trust
        string name;  // the name of the trust, like 'trust for Bob's son'
        address settlor;  // the settlor of the trust
        address beneficiary;  // the beneficiary of the trust, such as Bob's son
        uint nextReleaseTime;  // when would the money begin to release to beneficiary
        uint timeInterval;  // how often the money is going to release to beneficiary
        uint amountPerTimeInterval;  // how much can a beneficiary to get the money
        uint totalAmount;  // total money in this trust
        bool revocable;  // is this trust revocable or irrevocable
    }

    /*
     * Event that a new trust is added
     *
     * @param name the name of the trust
     * @param settlor the settlor address of the trust
     * @param beneficiary the beneficiary address of the trust
     * @param trustId the trustId of the trust
     * @param startReleaseTime will this trust start to release money, UTC in seconds
     * @param timeInterval how often can a beneficiary to get the money in seconds
     * @param amountPerTimeInterval how much can a beneficiary to get the money
     * @param totalAmount how much money are put in the trust
     * @param revocable whether this trust is revocalbe
     */
    event TrustAdded(
        string name,
        address indexed settlor,
        address indexed beneficiary,
        uint indexed trustId,
        uint startReleaseTime,
        uint timeInterval,
        uint amountPerTimeInterval,
        uint totalAmount,
        bool revocable
    );

    /*
     * Event that new fund are added into a existing trust
     *
     * @param trustId the trustId of the trust
     * @param amount how much money are added into the trust
     */
    event TrustFundAdded(uint indexed trustId, uint amount);

    /*
     * Event that a trust is finished
     *
     * @param trustId the trustId of the trust
     */
    event TrustFinished(uint indexed trustId);

    /*
     * Event that a trust is releaseed
     *
     * @param trustId the trustId of the trust
     */
    event TrustReleased(
        uint indexed trustId,
        address indexed beneficiary,
        uint amount,
        uint nextReleaseTime
    );

    /*
     * Event that a trust is revoked
     *
     * @param trustId the trustId of the trust
     */
    event TrustRevoked(uint indexed trustId);

    /*
     * Event that beneficiary get some money from the contract
     *
     * @param beneficiary the address of beneficiary
     * @param totalAmount how much the beneficiary released from this contract
     */
    event Release(address indexed beneficiary, uint totalAmount);

    /*
     * Get the balance in this contract, which is not send to any trust
     * @return the balance of the settlor in this contract
     *
     */
    function getBalance(address account) external view returns (uint balance);

    /*
     * If money is send to this contract by accident, can use this
     * function to get money back ASAP.
     *
     * @param to the address money would send to
     * @param amount how much money are added into the trust
     */
    function sendBalanceTo(address to, uint amount) external;

    /*
     * Get beneficiary's all trusts
     *
     * @return array of trusts which's beneficiary is the tx.orgigin
     */
    function getTrustListAsBeneficiary(address account)
        external
        view
        returns(Trust[] memory);


    /*
     * Get settlor's all trusts
     *
     * @return array of trusts which's settlor is the tx.orgigin
     */
    function getTrustListAsSettlor(address account)
        external
        view
        returns(Trust[] memory);

    /*
     * Add a new trust from settlor's balance in this contract.
     *
     * @param name the trust's name
     * @param beneficiary the beneficiary's address to receive the trust fund
     * @param startReleaseTime the start time beneficiary can start to get money,
                               UTC seconds
     * @param timeInterval how often the beneficiary can get money
     * @param amountPerTimeInterval how much money can beneficiary get after one timeInterval
     * @param totalAmount how much money is added to the trust
     * @param revocable whether this trust is revocable
     */
    function addTrustFromBalance(
        string memory name,
        address beneficiary,
        uint startReleaseTime,
        uint timeInterval,
        uint amountPerTimeInterval,
        uint totalAmount,
        bool revocable
    )
        external
        returns (uint trustId);

    /*
     * Add a new trust by pay
     *
     * @param name the trust's name
     * @param beneficiary the beneficiary's address to receive the trust fund
     * @param startReleaseTime the start time beneficiary can start to get money,
                               UTC seconds
     * @param timeInterval how often the beneficiary can get money
     * @param amountPerTimeInterval how much money can beneficiary get after one timeInterval
     * @param revocable whether this trust is revocalbe
     */
    function addTrust(
        string memory name,
        address beneficiary,
        uint startReleaseTime,
        uint timeInterval,
        uint amountPerTimeInterval,
        bool revocable
    )
        external
        payable
        returns (uint trustId);

    /*
     * Set trust to irrevocable
     *
     * @param trustId the trustId settlor want to set irrevocable
     */
    function setIrrevocable(uint trustId) external;

    /*
     * Revoke a trust, withdraw all the money out
     *
     * @param trustId the trustId settlor want to top up
     */
    function revoke(uint trustId) external;

    /*
     * Top up a trust by payment
     * @param trustId the trustId settlor want to top up
     */
    function topUp(uint trustId) external payable;

    /*
     * Top up from balance to a trust by trustId
     *
     * @param trustId the trustId settlor want add to top up
     * @param amount the amount of money settlor want to top up
     */
    function topUpFromBalance(uint trustId, uint amount) external;

    /*
     * Beneficiary release one trust asset by this function
     *
     * @param trustId the trustId beneficiary want to release
     *
     */
    function release(uint trustId) external;

    /*
     * Beneficiary release one trust asset by this function
     *
     * @param trustId the trustId beneficiary want to release
     * @param to the address beneficiary want to release to
     *
     */
    function releaseTo(uint trustId, address to) external;

    /*
     * Beneficiary get token by this function, release all the
     * trust releaeable assets in the contract
     */
    function releaseAll() external;

    /*
     * Beneficiary get token by this function, release all the
     * trust releaeable assets in the contract
     *
     * @param to the address beneficiary want to release to
     */
    function releaseAllTo(address to) external;

}
