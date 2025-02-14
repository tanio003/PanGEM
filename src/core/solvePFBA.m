function [mu] = solvePFBA(x,model,k_cat)

initSol = solveLP(model);

% Assign upper and lower bounds based on vmax = x*kcat. Need to consider
% the directionality of the reaction. 
for a = 1:numel(x)
    geneRxn_idx = find(model.rxnGeneMat(:,a));
    if ~isempty(geneRxn_idx)
        for b = 1:numel(geneRxn_idx)
            if x(a) == 0
                x(a) = abs(tempSol.x(geneRxn_idx(b)));
            end
            if model.ub(geneRxn_idx(b)) > 0 & model.lb(geneRxn_idx(b)) == 0
                model.ub(geneRxn_idx(b)) = x(a) .* k_cat(a) .* (1./model.geneProductMW(a)) .* (6.022e23) .* 1.2;
            elseif model.ub(geneRxn_idx(b)) == 0 & model.lb(geneRxn_idx(b)) < 0
                model.lb(geneRxn_idx(b)) = -x(a) .* k_cat(a) .* (1./model.geneProductMW(a)) .* (6.022e23) .* 1.2;
            elseif model.lb(geneRxn_idx(b)) < 0 & model.ub(geneRxn_idx(b)) > 0
                model.lb(geneRxn_idx(b)) = -x(a) .* k_cat(a) .* (1./model.geneProductMW(a)) .* (6.022e23) .* 1.2;
                model.ub(geneRxn_idx(b)) = x(a) .* k_cat(a) .* (1./model.geneProductMW(a)) .* (6.022e23) .* 1.2;
            end
        end
    end
        
end

% Assign x vector to S

enzyme_idx = find(contains(model.mets,'E_K'));
genePresent_idx = find(model.orthologPresent);
BOF_idx = find(strcmp(model.rxns,'BIOMASSCRUDE'));
BOF_coefs = -x(genePresent_idx);
BOF_coefs2 = 0.1.*(BOF_coefs ./ max(abs(BOF_coefs)));
model.S(enzyme_idx,BOF_idx) = BOF_coefs2;

% solve updated model
sol = solveLP(model);
if sol.stat
    mu = -sol.f;
else
    mu = NaN;
end

end
