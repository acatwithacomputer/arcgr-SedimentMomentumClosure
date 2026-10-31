from pysr import PySRRegressor

def customObjective(selectedNorm):

    if selectedNorm == "L2":
        print("Using norm: " + selectedNorm)
        objective = """
            function eval_loss(tree, dataset::Dataset{T,L}, options)::L where {T,L}
            # See https://astroautomata.com/SymbolicRegression.jl/dev/types/#DynamicExpressions.EquationModule.Node
            is_negative_constant(node) = node.degree == 0 && node.constant && node.val::T < 0
            # (The ::T part is not required, but it just speeds it up as then Julia knows it isn't `nothing`)

            # Will walk through tree and count number of times this function is true
            num_negative_constants = count(is_negative_constant, tree)
            #  (Tree utilities are defined here: https://github.com/SymbolicML/DynamicExpressions.jl/blob/master/src/base.jl,
            #  and let you treat an expression like a Julia collection)

            if num_negative_constants > 0
                # Return 1000 times the number of negative constants as a regularization penalty
                return L(1000 * num_negative_constants)
            end

            prediction, flag = eval_tree_array(tree, dataset.X, options)
            if !flag
                return L(Inf)
            end
            return sqrt(sum((prediction .- dataset.y) .^ 2) / sum(dataset.y .^2)) * 100
            end
            """
    elif selectedNorm == "L1":
        print("Using norm: " + selectedNorm)
        objective = """
            function eval_loss(tree, dataset::Dataset{T,L}, options)::L where {T,L}
            # See https://astroautomata.com/SymbolicRegression.jl/dev/types/#DynamicExpressions.EquationModule.Node
            is_negative_constant(node) = node.degree == 0 && node.constant && node.val::T < 0
            # (The ::T part is not required, but it just speeds it up as then Julia knows it isn't `nothing`)

            # Will walk through tree and count number of times this function is true
            num_negative_constants = count(is_negative_constant, tree)
            #  (Tree utilities are defined here: https://github.com/SymbolicML/DynamicExpressions.jl/blob/master/src/base.jl,
            #  and let you treat an expression like a Julia collection)

            if num_negative_constants > 0
                # Return 1000 times the number of negative constants as a regularization penalty
                return L(1000 * num_negative_constants)
            end

            prediction, flag = eval_tree_array(tree, dataset.X, options)
            if !flag
                return L(Inf)
            end
            return sum(abs.(prediction .- dataset.y)) / sum(abs.(dataset.y )) * 100
            end
            """
    elif selectedNorm == "Linf":
        print("Using norm: " + selectedNorm)
        objective = """
            function eval_loss(tree, dataset::Dataset{T,L}, options)::L where {T,L}
            # See https://astroautomata.com/SymbolicRegression.jl/dev/types/#DynamicExpressions.EquationModule.Node
            is_negative_constant(node) = node.degree == 0 && node.constant && node.val::T < 0
            # (The ::T part is not required, but it just speeds it up as then Julia knows it isn't `nothing`)

            # Will walk through tree and count number of times this function is true
            num_negative_constants = count(is_negative_constant, tree)
            #  (Tree utilities are defined here: https://github.com/SymbolicML/DynamicExpressions.jl/blob/master/src/base.jl,
            #  and let you treat an expression like a Julia collection)

            if num_negative_constants > 0
                # Return 1000 times the number of negative constants as a regularization penalty
                return L(1000 * num_negative_constants)
            end

            prediction, flag = eval_tree_array(tree, dataset.X, options)
            if !flag
                return L(Inf)
            end
            return maximum(abs.((prediction .- dataset.y) ./ dataset.y))  * 100
            end
            """
    return objective

def runPySRLinear(X,Y,nProc,nIter,norm):
    objective = customObjective(norm)
    model = PySRRegressor(
        procs = nProc,
        populations = 24,
        population_size=50,
        # ^ Slightly larger populations, for greater diversity.
        niterations=nIter,  # < Increase me for better results
        ncycles_per_iteration=2000, 
        # ^ Generations between migrations.
        maxsize=25,
        # ^ Allow greater complexity.
        binary_operators=["+", "*", "/", "^"],
        unary_operators=[],
        extra_sympy_mappings={},
        # ^ Define operator for SymPy as well
        complexity_of_constants=2,
        # ^ Punish constants more than variables
        complexity_of_operators={
            "^": 2
        },
        constraints={
            "^": (-1,2),
        },
        nested_constraints={
            "^": {"^":0},
        },
        turbo=True,
        # ^ Faster evaluation (experimental)
        weight_randomize=0.01,
        # ^ Randomize the tree much more frequently
        loss_function=objective,
        #elementwise_loss="loss(prediction, target) = abs(prediction - target)/target*100",
        # ^ Custom loss function (julia syntax)
        #warmup_maxsize_by = .5,
        # ^ Fraction of time before moving on to more complexity
        #select_k_features=5,
    )

    model.fit(X, Y)
    return

def runPySRQuadratic(X,Y,nProc,nIter,norm):
    objective = customObjective(norm)
    model = PySRRegressor(
        procs = nProc,
        populations = 24,
        population_size=50, #75,
        # ^ Slightly larger populations, for greater diversity.
        niterations=nIter,  # < Increase me for better results
        ncycles_per_iteration=2000, 
        # ^ Generations between migrations.
        maxsize=30,
        # ^ Allow greater complexity.
        binary_operators=["+", "*", "/", "^"],#"inv(x,y)= x ^ (-y)"],
        unary_operators=[], 
        extra_sympy_mappings={
            #"inv": lambda x, y: x**(-y),
        }, 
        # ^ Define operator for SymPy as well
        complexity_of_constants=2,
        # ^ Punish constants more than variables
        complexity_of_operators={
            "^": 1,
            #"inv":1,
        },
        constraints={
            "^": (-1,2),
            #"inv":(0, 2)
        },
        nested_constraints={
            "^": {"^":0},
            #"inv": {"inv":0, "^":0, "/":0}
        },
        turbo=True,
        # ^ Faster evaluation (experimental)
         weight_randomize=0.01,
        # ^ Randomize the tree much more frequently
        loss_function=objective,
        # ^ Custom loss function (julia syntax)
        #warmup_maxsize_by = .5,
        # ^ Fraction of time before moving on to more complexity
        #select_k_features=6,
        #precision=64
    )
    model.fit(X, Y)
    return

def runPySRRfit(X,Y,nProc,nIter,norm):
    objective = customObjective(norm)
    model = PySRRegressor(
        procs = nProc,
        populations = 24,
        population_size=50,
        # ^ Slightly larger populations, for greater diversity.
        niterations=nIter,  # < Increase me for better results
        ncycles_per_iteration=2000, 
        # ^ Generations between migrations.
        maxsize=25,
        # ^ Allow greater complexity.
        binary_operators=["+", "*", "^"],#"inv(x,y)= x ^ (-y)"],
        unary_operators=[], 
        extra_sympy_mappings={}, 
        # ^ Define operator for SymPy as well
        complexity_of_constants=1,
        # ^ Punish constants more than variables
        complexity_of_operators={
            "^": 1,
            #"inv":1,
        },
        constraints={
            "^": (1,1),
            #"inv":(0, 2)
        },
        nested_constraints={
            "^": {"^":0},
            #"inv": {"inv":0, "^":0, "/":0}
        },
        turbo=True,
        # ^ Faster evaluation (experimental)
         weight_randomize=0.01,
        # ^ Randomize the tree much more frequently
        loss_function=objective,
        # ^ Custom loss function (julia syntax)
        #warmup_maxsize_by = .5,
        # ^ Fraction of time before moving on to more complexity
        #select_k_features=6,
        #precision=64
    )
    model.fit(X, Y)
    return