//SPDX-License-Identifier: MIT
pragma solidity 0.8.12;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./ICallerContract.sol";

contract EthPriceOracle is AccessControl {
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

    struct Response {
        address oracleAddress;
        address callerAddress;
        uint256 ethPrice;
    }

    uint256 private randNonce = 0;
    uint256 private modulus = 1000;
    uint256 private numOracles = 0;
    uint256 private THRESHOLD = 0;
    mapping(uint256 => bool) pendingRequests;
    mapping(uint256 => Response[]) requestIdToResponse;

    event GetLatestEthPriceEvent(address callerAddress, uint256 id);
    event SetLatestEthPriceEvent(uint256 ethPrice, address callerAddress);
    event AddOracleEvent(address oracleAddress);
    event RemoveOracleEvent(address oracleAddress);
    event SetThresholdEvent(uint256 threshold);

    constructor() {
        _grantRole(OWNER_ROLE, msg.sender);
    }

    function addOracle(address _oracle) public {
        require(hasRole(OWNER_ROLE, msg.sender), "Not an owner!");
        require(!hasRole(ORACLE_ROLE, _oracle), "Already an oracle!");
        _grantRole(ORACLE_ROLE, _oracle);
        numOracles++;
        emit AddOracleEvent(_oracle);
    }

    function removeOracle(address _oracle) public {
        require(hasRole(OWNER_ROLE, msg.sender), "Not an owner!");
        require(hasRole(ORACLE_ROLE, _oracle), "Not an oracle!");
        require(numOracles > 1, "Do not remove the last oracle!");
        revokeRole(ORACLE_ROLE, _oracle);
        numOracles--;
        emit RemoveOracleEvent(_oracle);
    }

    function setThreshold(uint256 _threshold) public {
        require(hasRole(OWNER_ROLE, msg.sender), "Not an owner!");
        THRESHOLD = _threshold;
        emit SetThresholdEvent(THRESHOLD);
    }

    function getLatestEthPrice() public returns (uint256) {
        randNonce++;
        uint256 id = uint256(
            keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))
        ) % modulus;
        pendingRequests[id] = true;
        emit GetLatestEthPriceEvent(msg.sender, id);
        return id;
    }

    function setLatestEthPrice(
        uint256 _ethPrice,
        address _callerAddress,
        uint256 _id
    ) public {
        require(hasRole(ORACLE_ROLE, msg.sender), "Not an oracle!");
        require(
            pendingRequests[_id],
            "This request is not in my pending list."
        );
        Response memory resp;
        resp = Response(msg.sender, _callerAddress, _ethPrice);
        requestIdToResponse[_id].push(resp);
        uint256 numResponses = requestIdToResponse[_id].length;
        if (numResponses == THRESHOLD) {
            uint256 computedEthPrice = 0;
            for (uint256 f = 0; f < requestIdToResponse[_id].length; f++) {
                computedEthPrice += requestIdToResponse[_id][f].ethPrice;
            }
            computedEthPrice = computedEthPrice / numResponses;
            delete pendingRequests[_id];
            delete requestIdToResponse[_id];
            ICallerContract callerContractInstance = ICallerContract(
                _callerAddress
            );
            callerContractInstance.callback(computedEthPrice, _id);
            emit SetLatestEthPriceEvent(computedEthPrice, _callerAddress);
        }
    }
}
