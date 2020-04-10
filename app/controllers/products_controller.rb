class ProductsController < ApplicationController
  before_action :authenticate_user!, except:[:index, :show]
  before_action :set_product, only: [:show, :edit, :update, :destroy]
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  
  def index
    @q = Product.ransack(params[:q])
    @products = @q.result(distinct: true)
    @categories = Category.all.order("id ASC").limit(13)

    # トップページにて使用予定
    # @ladies_products = Product.where() 
  end

  def new
    @product = Product.new
    @image = @product.images.build
    @category = Category.all.order("id ASC").limit(13)
  end

  def create
    @product = Product.new(product_params)
    @category = Category.all.order("id ASC").limit(13)
      if @product.save
          params[:images]["image"].each do |image|
            @image = @product.images.create!(image: image)
          end
        redirect_to root_path
      else
        @product.images.build
        render action: 'new'
      end
  end

  def show
    @top_image = @product.images.first
    @images = @product.images

    # SOLD OUT確認用
    @transaction = Transaction.where(product_id: @product.id)
  end

  def edit
    @category = Category.all.order("id ASC").limit(13)
    @product = Product.find(params[:id]).presence || "商品は存在しません"
    

    #カテゴリー編集用
    # 登録されている商品の孫カテゴリーのレコードを取得し、孫カテゴリー選択肢用の配列作成
    @selected_category = @product.category
    @category_grandchildren_array = []
      Category.find("#{@selected_category.id}").siblings.each do |grandchild|
        grandchildren_hash = {id: "#{grandchild.id}", name: "#{grandchild.name}"}
        @category_grandchildren_array << grandchildren_hash
      end
    # binding.pry
    # 選択されている子カテゴリーのレコードを取得し、子カテゴリー選択肢用の配列作成
    @selected_child_category = @selected_category.parent
    @category_children_array = []
      Category.find("#{@selected_child_category.id}").siblings.each do |child|
        children_hash = {id: "#{child.id}", name: "#{child.name}"}
        @category_children_array << children_hash
      end
    # 選択されている親カテゴリーのレコードを取得し、親カテゴリー選択肢用の配列作成
    @selected_parent_category = @selected_category.parent
    @category_parents_array = []
      Category.find("#{@selected_parent_category.id}").siblings.each do |parent|
        parent_hash = {id: "#{parent.id}", name: "#{parent.name}"}
        @category_parents_array << parent_hash
      end

  end

  def update
    @product = current_user.products.find(params[:id]).presence || "商品は存在しません"
    @category = Category.all.order("id ASC").limit(13)
    if @product.update(product_params)
      redirect_to product_path
    else
      render 'edit'
    end  
  end

  def destroy
    @product = current_user.products.find(params[:id])
    if @product.destroy
      redirect_to root_path
    else
      render 'show'
    end
  end

  def category_children  
    @category_children = Category.find(params[:productCategory]).children 
  end

  def category_grandchildren
    @category_grandchildren = Category.find(params[:productCategory]).children
  end

  private
  
  def product_params
    params.require(:product).permit(:name, :description, :status, :delivery_charge, :delivery_method, :delivery_prefecture, :delivery_days, :size, :brand, :price, :transaction_id, :category_id,
      images_attributes: [:image, :_destroy, :id]).merge(user_id: current_user.id)
  end

  def set_product
    @product = Product.find(params[:id])
  end

  def set_user
    @user = User.find(@product.user_id)
  end

end