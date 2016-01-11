JiraTestReports::Application.routes.draw do

  resources :test_preparations

  resources :options
  resources :last_reports

	root 'projects#index'
	
	get 'filtered' => 'projects#filtered'
	get 'daily_report' => 'projects#daily_report'
	get 'set_baseline' => 'projects#set_baseline'
	get 'tfpg_1' => 'projects#tfpg_1'
	get 'tfpg_2' => 'projects#tfpg_2'
	get 'tfpg_3' => 'projects#tfpg_3'
	get 'get_issues_dynamics' => 'projects#get_issues_dynamics'
	get 'issues_dynamics' => 'projects#issues_dynamics'
	get 'cogeco_pg' => 'projects#cogeco_pg'

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
