/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC165.sol";
import "./Address.sol";
import "./BeaconDeployer.sol";
import "./Ownership.sol";
import "./BeaconProxyDeployer.sol";
import "./MinimalProxyDeployer.sol";
import "./Multicall.sol";
import "./IFactory.sol";

/**
 * @title Factory V1
 * @author yoonsung.eth
 * @notice Abstract reusable contract into template and deploy them in small sizes `minimal proxy` and `beacon proxy`.
 * This contract can receive a fee lower than the deploy cost, and registered addresses do not have to pay the fee.
 * Beacon is managed in this contract, it can be useful if you need a scalable upgrade through the `beacon proxy`.
 * @dev The template to be registered may or may not have an `initialize` function.
 * However, at least a ERC173 and multicall for directed at self must be implemented.
 */
contract FactoryV1 is Ownership, Multicall, IFactory {
    using Address for address;

    /**
     * @notice template key for template info.
     */
    mapping(bytes32 => TemplateInfo) public templates;

    /**
     * @notice registered template for nonce.
     */
    mapping(address => uint256) private nonceForTemplate;

    /**
     * @notice template count.
     */
    uint256 public nonce = 1;

    /**
     * @notice base fee
     */
    uint256 public baseFee;

    /**
     * @notice fee collector
     */
    address payable public feeTo;

    /**
     * @notice requiring on deploy, allowlist contract.
     * @param feeAmount basic fee for ether amount
     * @param feeToAddr fee collector address
     */
    constructor(uint256 feeAmount, address payable feeToAddr) {
        baseFee = feeAmount;
        feeTo = feeToAddr;
        nonceForTemplate[address(0)] = type(uint256).max;
    }

    /**
     * @notice template id를 통해서 minimal proxy와 minimal beacon proxy를 배포하는 함수.
     * @dev 일반적으로 배포되는 컨트랙트와 같이 컨트랙트가 생성될 때 초기화 함수를 실행해야 한다면, initializationCallData에 호출할 함수를
     * serialize하여 주입하여야 합니다. 컨트랙트 소유권을 별도로 관리해야하는 경우 multicall을 통해서 명시적인 소유권 이전이 되어야 합니다.
     * @param templateId 배포할 컨트랙트의 template id
     * @param isBeacon 비콘으로 배포해야 할 것인지 결정하는 인자.
     * @param initializationCallData 컨트랙트가 생성될 때 호출할 직렬화된 초기화 함수 정보
     * @param calls 컨트랙트가 배포된 이후, 필요한 일련의 함수 호출 정보
     */
    function deploy(
        bool isBeacon,
        bytes32 templateId,
        bytes memory initializationCallData,
        bytes[] memory calls
    ) external payable returns (address deployed) {
        // 템플릿을 배포하기 위한 수수료가 적정 수준인지 확인.
        require(baseFee <= msg.value || owner == msg.sender, "Factory/Incorrect-amounts");
        // 수수료 전송
        feeTransfer(feeTo, msg.value);
        // 배포할 템플릿의 정보
        TemplateInfo memory tmp = templates[templateId];

        deployed = isBeacon
            ? BeaconProxyDeployer.deploy(tmp.btemplate, initializationCallData)
            : MinimalProxyDeployer.deploy(tmp.template, initializationCallData);

        // 부수적으로 호출할 데이터가 있다면, 배포된 컨트랙트에 추가적인 call을 할 수 있음.
        if (calls.length > 0) IMulticall(deployed).multicall(calls);
        // 이벤트 호출
        emit Deployed(deployed, msg.sender);
    }

    /**
     * @notice template id와 외부에서 관리되는 seed를 통해서 minimal proxy와 minimal beacon proxy를 배포하는 함수.
     * @dev 일반적으로 배포되는 컨트랙트와 같이 컨트랙트가 생성될 때 초기화 함수를 실행해야 한다면, initializationCallData에 호출할 함수를
     * serialize하여 주입하여야 합니다. 컨트랙트 소유권을 별도로 관리해야하는 경우 multicall을 통해서 명시적인 소유권 이전이 되어야 합니다.
     * @param seed 컨트랙트 주소 확정에 필요한 외부 seed
     * @param isBeacon 비콘으로 배포해야 할 것인지 결정하는 인자.
     * @param templateId 배포할 컨트랙트의 template id
     * @param initializationCallData 컨트랙트가 생성될 때 호출할 직렬화된 초기화 함수 정보
     * @param calls 컨트랙트가 배포된 이후, 필요한 일련의 함수 호출 정보
     */
    function deployWithSeed(
        string memory seed,
        bool isBeacon,
        bytes32 templateId,
        bytes memory initializationCallData,
        bytes[] memory calls
    ) external payable returns (address deployed) {
        // 템플릿을 배포하기 위한 수수료가 적정 수준인지 확인.
        require(baseFee <= msg.value || owner == msg.sender, "Factory/Incorrect-amounts");
        // 수수료 전송
        feeTransfer(feeTo, msg.value);
        // 배포할 템플릿의 정보
        TemplateInfo memory tmp = templates[templateId];

        deployed = isBeacon
            ? BeaconProxyDeployer.deploy(seed, tmp.btemplate, initializationCallData)
            : MinimalProxyDeployer.deploy(seed, tmp.template, initializationCallData);

        // 부수적으로 호출할 데이터가 있다면, 배포된 컨트랙트에 추가적인 call을 할 수 있음.
        if (calls.length > 0) IMulticall(deployed).multicall(calls);
        // 이벤트 호출
        emit Deployed(deployed, msg.sender);
    }

    /**
     * @notice template id와 초기화 데이터 통해서 minimal proxy와 minimal beacon proxy로 배포할 주소를 미리 파악하는 함수
     * @dev 연결된 지갑 주소에 따라 생성될 지갑 주소가 변경되므로, 연결되어 있는 주소를 필수로 확인하여야 합니다.
     * @param isBeacon 비콘으로 배포해야 할 것인지 결정하는 인자.
     * @param templateId 배포할 컨트랙트의 template id
     * @param initializationCallData 컨트랙트가 생성될 때 호출할 직렬화된 초기화 함수 정보
     */
    function compute(
        bool isBeacon,
        bytes32 templateId,
        bytes memory initializationCallData
    ) external view returns (address deployable) {
        TemplateInfo memory tmp = templates[templateId];
        deployable = isBeacon
            ? BeaconProxyDeployer.calculateAddress(tmp.btemplate, initializationCallData)
            : MinimalProxyDeployer.calculateAddress(tmp.template, initializationCallData);
    }

    /**
     * @notice template id와 Seed 문자열, 초기화 데이터 통해서 minimal proxy와 minimal beacon proxy로 배포할 주소를 미리 파악하는 함수
     * @dev 연결된 지갑 주소에 따라 생성될 지갑 주소가 변경되므로, 연결되어 있는 주소를 필수로 확인하여야 합니다.
     * @param seed 컨트랙트에 사용할 seed 문자열
     * @param isBeacon 비콘으로 배포해야 할 것인지 결정하는 인자.
     * @param templateId 배포할 컨트랙트의 template id
     * @param initializationCallData 컨트랙트가 생성될 때 호출할 직렬화된 초기화 함수 정보
     */
    function computeWithSeed(
        string memory seed,
        bool isBeacon,
        bytes32 templateId,
        bytes memory initializationCallData
    ) external view returns (address deployable) {
        TemplateInfo memory tmp = templates[templateId];
        deployable = isBeacon
            ? BeaconProxyDeployer.calculateAddress(seed, tmp.btemplate, initializationCallData)
            : MinimalProxyDeployer.calculateAddress(seed, tmp.template, initializationCallData);
    }

    /**
     * @notice Factori.eth에 등록되지 않은 컨트랙트를 Template로 하여 Minimal Proxy로 배포합니다.
     * @param templateAddr 템플릿으로 사용할 이미 배포된 컨트랙트 주소
     * @param initializationCallData 배포되면서 호출되어야 하는 초기화 함수
     * @param calls 초기화 함수 이외에, 호출되어야 하는 함수들의 배열
     */
    function clone(
        address templateAddr,
        bytes memory initializationCallData,
        bytes[] memory calls
    ) external payable returns (address deployed) {
        require(nonceForTemplate[templateAddr] == 0, "Factory/Registered-Template");
        // 템플릿을 배포하기 위한 수수료가 적정 수준인지 확인.
        require(baseFee == msg.value || owner == msg.sender, "Factory/Incorrect-amounts");
        // 수수료 전송
        feeTransfer(feeTo, msg.value);
        deployed = MinimalProxyDeployer.deploy(templateAddr, initializationCallData);
        if (calls.length > 0) IMulticall(deployed).multicall(calls);
    }

    /**
     * @notice Factori.eth에 등록되지 않은 컨트랙트를 Template로 하여 minimal proxy로 배포할 주소를 미리 파악하는 함수
     * @dev 연결된 지갑 주소에 따라 생성될 지갑 주소가 변경되므로, 연결되어 있는 주소를 필수로 확인하여야 합니다.
     * @param templateAddr 배포할 컨트랙트의 template id
     * @param initializationCallData 컨트랙트가 생성될 때 호출할 직렬화된 초기화 함수 정보
     */
    function computeClone(address templateAddr, bytes memory initializationCallData)
        external
        view
        returns (address deployable)
    {
        deployable = MinimalProxyDeployer.calculateAddress(templateAddr, initializationCallData);
    }

    /**
     * @notice template id에 따라서 컨트랙트를 배포하기 위한 필요 가격을 가져오는 함
     * @dev 연결된 지갑 주소에 따라 생성될 지갑 주소가 변경되므로, 연결되어 있는 주소를 필수로 확인하여야 합니다.
     * @return price 이더리움으로 구성된 값을 가짐.
     */
    function getPrice() external view returns (uint256 price) {
        price = baseFee;
    }

    /**
     * @notice 템플릿으로 사용되기 적합한 인터페이스가 구현된 컨트랙트를 템플릿으로 가격과 함께 등록함.
     * @dev 같은 템플릿이 비콘과, 일반적인 템플릿으로 등록될 수 있습니다. 따라서 선택적으로 사용 가능합니다.
     * @param templateAddr 템플릿으로 사용될 컨트랙트의 주소
     */
    function addTemplate(address templateAddr) external onlyOwner {
        require(nonceForTemplate[templateAddr] == 0, "Factory/Non-Valid");
        bytes32 key = keccak256(abi.encode(templateAddr, nonce));
        address beaconAddr = BeaconDeployer.deploy(templateAddr);
        templates[key] = TemplateInfo({template: templateAddr, btemplate: beaconAddr});
        nonceForTemplate[templateAddr] = nonce++;
        emit NewTemplate(key, templateAddr, beaconAddr);
    }

    /**
     * @notice 등록된 템플릿의 정보를 변경하는 함수, 비콘인 경우에는 템플릿을 업데이트 할 수 있으나 비콘이 아니라면 업데이트 불가능.
     * @param key 업데이트 될 템플릿의 아이디
     * @param templateAddr 비콘일 경우 템플릿 주소, 템플릿 소유주 주소를 순서대로 인코딩
     */
    function updateTemplate(bytes32 key, address templateAddr) external onlyOwner {
        require(templateAddr != address(0), "Factory/Non-Valid");
        require(nonceForTemplate[templateAddr] == 0, "Factory/registered-before");
        require(templateAddr.isContract(), "Factory/is-not-Contract");
        TemplateInfo memory tmp = templates[key];
        tmp.template = templateAddr;
        (bool success, ) = tmp.btemplate.call(abi.encode(templateAddr));
        assert(success);
        templates[key] = tmp;
        emit UpdatedTemplate(key, tmp.template);
    }

    /**
     * @notice 등록된 템플릿을 삭제하는 함수
     * @param key 삭제될 템플릿의 아이디
     */
    function removeTemplate(bytes32 key) external onlyOwner {
        TemplateInfo memory tmp = templates[key];
        require(tmp.template != address(0), "Factory/Non-Exist");
        delete templates[key];
        emit DeletedTemplate(key);
    }

    /**
     * @notice 고정 수수료를 변경
     * @param newFee 변경된 수수료
     */
    function changeFee(uint256 newFee) external onlyOwner {
        uint256 prevFee = baseFee;
        baseFee = newFee;
        emit FeeChanged(prevFee, newFee);
    }

    /**
     * @notice 수수료를 수취할 대상 변경
     * @param newFeeTo 수취할 대상 주소
     */
    function changeFeeTo(address payable newFeeTo) external onlyOwner {
        address prevFeeTo = feeTo;
        feeTo = newFeeTo;
        emit FeeToChanged(prevFeeTo, newFeeTo);
    }

    /**
     * @notice Factori.eth에 쌓여있는 ETH와 토큰을 호출하여, 수수료 수취 주소에 전송함
     * @param tokenAddr 수취할 토큰 주소
     */
    function collect(address tokenAddr) external onlyOwner {
        IERC20(tokenAddr).transfer(feeTo, IERC20(tokenAddr).balanceOf(address(this)));
    }

    function recoverOwnership(address deployed, address to) external onlyOwner {
        IERC173(deployed).transferOwnership(to);
    }

    function feeTransfer(address to, uint256 amount) internal returns (bool callStatus) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
            let returnDataSize := returndatasize()
            if iszero(callStatus) {
                returndatacopy(0, 0, returnDataSize)
                revert(0, returnDataSize)
            }
        }
    }
}
