%% TIMER WAITBAR WITH CUSTOMIZABLE TITLE
%  Version : v1.02
%  Author  : E. Ogier
%  Release : 29th oct. 2020
%
%  VERSIONS
%  - v1.0  (15th mar 2016): intial version
%  - v1.01 (28th mar 2016): modification of 'delete' method to delete the current waitbar if the last iteration is not reached
%  - v1.02 (29th oct 2020): the waitbar's title can be customized
%
%  USAGE
%  - TWB = Timerwaitbar(ITERATIONS); Creation of a Timerwaitbar for ITERATIONS loops
%  - TWB.update();                   Timerwaitbar update when a loop is performed
%  - STATUS = TWB.isinterrupted();   Timerwaitbar status ([false]/true if cancelation)
%  - TWB.delete();                   Timerwaitbar destruction
%
%  DESCRIPTION OF TIMER WAITBAR FIELDS
%  - WIP: Work In Progress [%]
%  - ETR: Estimated Time Remaining  [HH:MM:SS] if ETR < 24h | [d'd' HH:MM:SS] if ETR >= 24h
%  - ETA: Estimated Time of Arrival [HH:MM:SS] if today)    | [ddd HH:MM]     if later
%
%  EXAMPLE
%  % Number of iterations
%  N = 50;
%  
%  % Creation of a timer waitbar object
%  TWB = Timerwaitbar(N);
%  % Or using the customizable title to create the timer waitbar object
%  TWB = Timerwaitbar(N, 'Your title');
%  
%  % Loop
%  for n = 1:N
%      
%      % Simulation of a task 
%      pause(1);   
%       
%      % Timer waitbar update
%      TWB.update();
%      
%      % Loop break if manual cancelation
%      if TWB.isinterrupted()
%          break
%      end
%      
%  end
%  
%  % Object deletion
%  TWB.delete();
%
%  Copyright (c) 2016, Eric Ogier
%  All rights reserved.
%  
%  Redistribution and use in source and binary forms, with or without
%  modification, are permitted provided that the following conditions are met:
%  
%  * Redistributions of source code must retain the above copyright notice, this
%    list of conditions and the following disclaimer.
%  
%  * Redistributions in binary form must reproduce the above copyright notice,
%    this list of conditions and the following disclaimer in the documentation
%    and/or other materials provided with the distribution
%  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
%  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
%  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
%  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
%  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
%  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
%  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
%  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
%  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
%  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

classdef Timerwaitbar < matlab.mixin.SetGet
   
    % Properties (private access)
    properties (Access = 'private')
        Interruption    = false; % Interruption status
        Iterations      = 0;     % Number of iterations to perform
        Waitbar         = [];    % Waitbar object
        Title;                   % Waitbar's tilte
        Counter         = 0;     % Iteration counter
        InitialTime     = 0;     % First iteration time
        InitialTimeDays = 0;     % First iteration time in whole days
    end
    
    % Methods
    methods
        
        % Constructor
        function Object = Timerwaitbar(Iterations, Title)
            
            if nargin == 0
                    error('You must input Iterations at least!');
            elseif nargin == 1
                Object.Title  = 'Calculating';
            else
                Object.Title  = Title;
            end
            
            Object.Iterations = Iterations;
            Object.Counter    = 0;
            
        end
        
        % Function 'isinterrupted' (cancelation status)
        function Status = isinterrupted(Object)
            
            Status = Object.Interruption;            
            
        end
        
        % Function 'update' (waitbar update)
        function Object = update(Object)
                                    
            % Time initialization
            if Object.Counter == 0
               Date = clock;
               Object.InitialTime = Date;               
               Object.InitialTimeDays = floor(datenum(Date));
            end
            
            % Waitbar creation
            if isempty(Object.Waitbar)
                Object.Waitbar = waitbar(0,'','Name',Object.Title,'CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
                setappdata(Object.Waitbar,'canceling',0);
            end
                        
            % Iterations counter increment
            Object.Counter = Object.Counter+1;
            
            % Progression
            p = Object.Counter/Object.Iterations;
                      
            % Elapsed time from first iteration
            dt = etime(clock,Object.InitialTime);
            
            % Estimations
            ETR = (1/p-1)*dt/86400;   % Estimated time remaining  [day]
            ETA = datenum(clock)+ETR; % Estimated time of arrival [day]
            
            % ETR string
            if ETR < 1
                ETRstring = datestr(ETR,'HH:MM:SS');    % ETR <  1day
            else
                ETRstring = datestr(ETR,'dd HH:MM:SS'); % ETR >= 1day
                ETRstring = strrep(ETRstring,' ','d ');
            end
            
            % ETA string
            if floor(ETA) == Object.InitialTimeDays
                ETAstring = datestr(ETA,'HH:MM:SS PM');  % ETA : today
            else
                ETAstring = datestr(ETA,'ddd HH:MM PM'); % ETA : later
            end
            
            % Progress bar update (WIP | ETR | ETA)
            waitbar(p,Object.Waitbar,sprintf('WIP: %.1f%%  |  ETR: %s  |  ETA: %s',100*p,ETRstring,ETAstring));
            
            % Interruption status
            Object.Interruption = getappdata(Object.Waitbar,'canceling');
            
            % Waitbar deletion (ending or cancelation)
            if p == 1 || Object.Interruption
                delete(Object.Waitbar);
            end
            
        end
        
        % Function 'delete'
        function Object = delete(Object)
            if ~isempty(Object.Waitbar)
                delete(Object.Waitbar);  
            end
            Object = [];
        end
        
    end
    
end
