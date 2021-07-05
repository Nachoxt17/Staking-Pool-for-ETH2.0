pragma solidity ^0.7.5;

//+-Tutorial:_ https://youtu.be/gq3LhxkDwfY https://github.com/ethereum/eth2.0-deposit-cli

//+-Deposit the Minimum of 32 Ether in the ETH2.0 Staking S.C.:_
interface IDepositContract {
    /**
    +-bytes calldata pubkey:_ Public Key, the Identifier for the Validator.
    +-bytes calldata withdrawal_credentials:_
    +-bytes calldata signature:_ Signature of the User that demostrates that actually wants to do this Deposit.
    +-bytes32 deposit_data_root:_
    */
    function deposit(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) external payable;
}

contract StakingPool {
    mapping(address => uint256) public balances;
    mapping(bytes => bool) public pubkeysUsed;
    IDepositContract public depositContract =
        IDepositContract(0x00000000219ab540356cBB839Cbe05303d7705Fa);
    address public admin;
    uint256 public end;
    bool public finalized;
    uint256 public totalInvested;
    uint256 public totalChange;
    mapping(address => bool) public changeClaimed;

    event NewInvestor(address investor);

    constructor() {
        admin = msg.sender;
        end = block.timestamp + 7 days;
    }

    function invest() external payable {
        require(block.timestamp < end, "too late");
        if (balances[msg.sender] == 0) {
            emit NewInvestor(msg.sender);
        }
        balances[msg.sender] += msg.value;
    }

    function finalize() external {
        require(block.timestamp >= end, "too early");
        require(finalized == false, "already finalized");
        finalized = true;
        totalInvested = address(this).balance;
        totalChange = address(this).balance % 32 ether;
    }

    //+-Get Earnings of Investment:_
    function getChange() external {
        require(finalized == true, "not finalized");
        require(balances[msg.sender] > 0, "not an investor");
        require(changeClaimed[msg.sender] == false, "change already claimed");
        changeClaimed[msg.sender] = true;
        uint256 amount = (totalChange * balances[msg.sender]) / totalInvested;
        msg.sender.send(amount);
    }

    function deposit(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) external {
        require(finalized == true, "too early");
        require(msg.sender == admin, "only admin");
        require(address(this).balance >= 32 ether);
        require(pubkeysUsed[pubkey] == false, "this pubkey was already used");
        depositContract.deposit{value: 32 ether}(
            pubkey,
            withdrawal_credentials,
            signature,
            deposit_data_root
        );
    }
}
