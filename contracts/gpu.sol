// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedGPUSharing {
    address public owner;
    string public name;
    string public symbol;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(string memory _name, string memory _symbol, uint256 _totalSupply) {
        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = _totalSupply;
        owner = msg.sender;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    

    enum GPUStatus { Idle, InUse, Disabled }
    enum State {Active, Fullfilled}

    struct GPU {
        string ipAddress;
        uint256 ratePerMinute;
        GPUStatus status;
        address provider;
    }

    struct Transaction {
        GPU gpuInstance;
        address user;
        uint256 allocationTimestamp;
        uint256 deallocationTimestamp;
        State status;
    }

    mapping(address => GPU) public providedGPUInstances;
    mapping (address => Transaction) public allocatedGPUInstances;
    uint256 public totalGPUInstances;

    event GPUAllocated(address indexed user, uint256 allocationTimestamp);
    event GPUReleased(address indexed user, uint256 deallocationTimestamp);
    event GPUDisabled(address indexed provider);
    event GPUAdded(address indexed provider, string ipAddress, uint256 ratePerMinute);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    modifier onlyGPUOwner() {
        require(providedGPUInstances[msg.sender].provider == msg.sender, "Not the GPU owner");
        _;
    }

    

    function addGPUInstance(string calldata ipAddress, uint256 ratePerMinute) external{
        providedGPUInstances[msg.sender] = GPU({
            ipAddress: ipAddress,
            ratePerMinute: ratePerMinute,
            status: GPUStatus.Idle,
            provider: msg.sender
        });
        totalGPUInstances++;
        emit GPUAdded(msg.sender, ipAddress, ratePerMinute);
    }

    function allocateGPU(address provider) external{
        require(totalGPUInstances != 0);
        require(providedGPUInstances[provider].status == GPUStatus.Idle, "GPU is not available");
        if (allocatedGPUInstances[msg.sender].allocationTimestamp == 0 || allocatedGPUInstances[msg.sender].status == State.Fullfilled) {
    // Perform the assignment only if the status is Inactive or another desired condition.
    allocatedGPUInstances[msg.sender] = Transaction({
        gpuInstance : providedGPUInstances[provider],
        user: msg.sender,
        allocationTimestamp: block.timestamp,
        deallocationTimestamp: 0,
        status: State.Active
    });
}
        emit GPUAllocated(msg.sender, allocatedGPUInstances[msg.sender].allocationTimestamp);
    }

    function releaseGPU() external payable {
        require(allocatedGPUInstances[msg.sender].status == State.Active, "GPU is not in use");

        allocatedGPUInstances[msg.sender].deallocationTimestamp = block.timestamp;
        allocatedGPUInstances[msg.sender].status = State.Fullfilled;
        allocatedGPUInstances[msg.sender].gpuInstance.status = GPUStatus.Idle;

         uint256 totalTimeUsed = allocatedGPUInstances[msg.sender].deallocationTimestamp - allocatedGPUInstances[msg.sender].allocationTimestamp;
         uint256 totalCost = (totalTimeUsed / 60) * allocatedGPUInstances[msg.sender].gpuInstance.ratePerMinute;

        // Transfer funds to the GPU provider
        /*
            msg.sender = user (jisko paise dene hai)
            allocatedGPUInstances[msg.sender].gpuInstance.provider = jisne gpu diya (isko paise bhejne hai)
function transfer(address allocatedGPUInstances[msg.sender].gpuInstance.provider,uint256 amount) public override returns(bool){
           _transfer(msg.sender,allocatedGPUInstances[msg.sender].gpuInstance.provider,amount);
         }
        */
        transfer(allocatedGPUInstances[msg.sender].gpuInstance.provider, totalCost);
        // IERC20(0xdD6ffF0101E5b3D03C91112801Cf49308F90B2E9).transfer(allocatedGPUInstances[msg.sender].gpuInstance.provider, totalCost);
        emit GPUReleased(msg.sender, allocatedGPUInstances[msg.sender].deallocationTimestamp);
    }
    
    

    function disableGPU() external{
        require(providedGPUInstances[msg.sender].status != GPUStatus.Disabled, "GPU is already disabled");
        providedGPUInstances[msg.sender].status = GPUStatus.Disabled;
        emit GPUDisabled(msg.sender);
    }

    function enableGPU() external{
        require(providedGPUInstances[msg.sender].status == GPUStatus.Disabled, "GPU is not disabled");
        providedGPUInstances[msg.sender].status = GPUStatus.Idle;
    }
}